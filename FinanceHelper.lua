local moonloader = require("moonloader")
local samp = require("lib.samp.events")

local imgui = require 'mimgui'
local encoding = require('encoding')
local u8 = encoding.UTF8
encoding.default = 'CP1251'
local new = imgui.new
local faicons = require('fAwesome6')
local font = {}
local https = require("ssl.https")
local lfs = require("lfs")
local WinState = new.bool()

local ffi = require("ffi")


local inicfg = require('inicfg')


local IniFileName = "FinanceHelper.ini"

local transactions = {
    BankWithdrawals = {},
    DepositWithdrawals = {},
    BankWithdrawGive = {},
    PlayerReceived = {},
    PlayerSent = {},
    DepositGive = {},
    CashIncome = {},  -- Доходы наличными (givePlayerMoney)
    CashExpense = {}

}


local lastMoney = getPlayerMoney()
local ini = inicfg.load({

    data = {
        totalWeekSalary = 0,
        totalWeekDeposit = 0,
        totalWeekAZ = 0,
        totalWeekPdCount = 0,

        totalSalary = 0,
        totalDeposit = 0,
        totalAZ = 0,

        tokenBot = "Введите Token бота",
        chatIdBot = "Введите ChatID",

        chbox_show_menu2 = false,    

        pos_x = 100, 
        pos_y = 100  ,

        chbox_show_salary_s = true,
        chbox_show_deposit_s = true,
        chbox_show_az_s = true,
        chbox_show_pdaycount_s = true,
        chbox_show_pday_timer = true,

        chbox_show_salary = true,
        chbox_show_deposit = true,
        chbox_show_az = true,
        chbox_show_pdaycount = true,

        chbox_show_total_week = true,


        chbox_send_player = false,
        chbox_send_player_me = false,
        chbox_give_bank = false,
        chbox_take_bank = false,
        chbox_give_deposit = false,
        chbox_take_deposit = false,

        chbox_autoOpenWindow = false,


    },

    weeklyEarnings_Salary = {
        [0] = 0, -- Воскресенье
        [1] = 0, -- Понедельник
        [2] = 0, -- Вторник
        [3] = 0, -- Среда
        [4] = 0, -- Четверг
        [5] = 0, -- Пятница
        [6] = 0  -- Суббота
    },

    weeklyEarnings_Deposit = {
        [0] = 0, -- Воскресенье
        [1] = 0, -- Понедельник
        [2] = 0, -- Вторник
        [3] = 0, -- Среда
        [4] = 0, -- Четверг
        [5] = 0, -- Пятница
        [6] = 0  -- Суббота
    },

    weeklyEarnings_az = {
        [0] = 0, -- Воскресенье
        [1] = 0, -- Понедельник
        [2] = 0, -- Вторник
        [3] = 0, -- Среда
        [4] = 0, -- Четверг
        [5] = 0, -- Пятница
        [6] = 0  -- Суббота
    },

    weeklyEarnings_paydaycount = {
        [0] = 0, -- Воскресенье
        [1] = 0, -- Понедельник
        [2] = 0, -- Вторник
        [3] = 0, -- Среда
        [4] = 0, -- Четверг
        [5] = 0, -- Пятница
        [6] = 0  -- Суббота
    },


  

    

   
}, IniFileName)

-- Ensure ini file is saved initially
inicfg.save(ini, IniFileName)





------------------Download lib-------------------------
local libDir = getWorkingDirectory() .. "/lib/"
local libPath = libDir .. "telegram.lua"
local downloadURL = "https://raw.githubusercontent.com/WenfostT/telegram/refs/heads/main/telegram_send.lua"

local function downloadLib()
    local body, code = https.request(downloadURL)
    if code == 200 then
        if not lfs.attributes(libDir) then
            lfs.mkdir(libDir)
        end
        local file = io.open(libPath, "w")
        if file then
            file:write(body)
            file:close()
            print("[Telegram] Библиотека успешно загружена!")
        else
            print("[Telegram] Ошибка записи файла!")
        end
    else
        print("[Telegram] Ошибка загрузки библиотеки! Код:", code)
    end
end

-- Проверяем и загружаем библиотеку при необходимости
if not lfs.attributes(libPath) then
    print("Библиотека не найдена, начинаю загрузу...")
    downloadLib()
end

package.loaded["lib.telegram"] = nil
os.rename(libDir .. "telegram_send.lua", libPath)

local telegram = require("lib.telegram")






-----------------------------AutoUpdateScript---------------------


local SCRIPT_VERSION = "1.1" -- Укажи текущую версию
local UPDATE_URL = "https://raw.githubusercontent.com/WenfostT/FinanceHelper/refs/heads/main/FinanceHelper.lua" -- Ссылка на твой скрипт на GitHub
local VERSION_URL = "https://raw.githubusercontent.com/WenfostT/FinanceHelper/refs/heads/main/version.txt" -- Ссылка на файл с версией
local TEMP_FILE = getWorkingDirectory() .. "/FinanceHelper_temp.lua" -- Временный файл для скачивания

-- Функция проверки и установки обновлений
function checkForUpdates()
    -- Скачиваем файл с версией
    local versionBody, versionCode = https.request(VERSION_URL)
    if versionCode ~= 200 then
        sampAddChatMessage("[FinanceHelper] Ошибка проверки обновлений: " .. versionCode, 0xFF5555)
        return
    end

    local remoteVersion = versionBody:match("(%d+%.%d+%.%d+)")
    if not remoteVersion then
        sampAddChatMessage("[FinanceHelper] Не удалось распознать версию на сервере!", 0xFF5555)
        return
    end

    -- Сравниваем версии
    if remoteVersion > SCRIPT_VERSION then
        sampAddChatMessage("[FinanceHelper] Обнаружена новая версия: " .. remoteVersion .. "! Качаю, братишка!", 0x27AE60)

        -- Скачиваем новый скрипт
        local scriptBody, scriptCode = https.request(UPDATE_URL)
        if scriptCode ~= 200 then
            sampAddChatMessage("[FinanceHelper] Ошибка скачивания обновления: " .. scriptCode, 0xFF5555)
            return
        end

        -- Сохраняем во временный файл
        local tempFile = io.open(TEMP_FILE, "w")
        if tempFile then
            tempFile:write(scriptBody)
            tempFile:close()

            -- Заменяем текущий скрипт
            local currentFilePath = getWorkingDirectory() .. "/FinanceHelper.lua" -- Укажи имя твоего файла
            os.remove(currentFilePath) -- Удаляем старый файл
            os.rename(TEMP_FILE, currentFilePath) -- Переименовываем новый

            sampAddChatMessage("[FinanceHelper] Обновление до " .. remoteVersion .. " установлено! Перезагружаю, гангстер!", 0x27AE60)
        

            -- Перезапуск скрипта (опционально, требует перезапуска MoonLoader)
            thisScript():reload()
        else
            sampAddChatMessage("[FinanceHelper] Ошибка записи файла обновления!", 0xFF5555)
        end
    else
        sampAddChatMessage("[FinanceHelper] У тебя последняя версия: " .. SCRIPT_VERSION, 0x27AE60)
    end
end

-----------------SaveTransactions---------------
local function saveTransactions()
    ini.transactions = ini.transactions or {}
    local i = 1
    for _, trans in ipairs(transactions.BankWithdrawals) do
        ini.transactions["Bank" .. i] = trans
        i = i + 1
    end
    i = 1
    for _, trans in ipairs(transactions.DepositWithdrawals) do
        ini.transactions["Dep" .. i] = trans
        i = i + 1
    end

    i = 1

    for _, trans in ipairs(transactions.DepositGive) do
        ini.transactions["Depp" .. i] = trans
        i = i + 1
    end

    i = 1
    for _, trans in ipairs(transactions.BankWithdrawGive) do
        ini.transactions["BankGive" .. i] = trans
        i = i + 1
    end
    i = 1
    for _, trans in ipairs(transactions.PlayerReceived) do
        ini.transactions["Recv" .. i] = trans
        i = i + 1
    end
    i = 1
    for _, trans in ipairs(transactions.PlayerSent) do          --DepositGive
        ini.transactions["Sent" .. i] = trans
        i = i + 1
    end

    i = 1
    for _, trans in ipairs(transactions.CashIncome) do
        ini.transactions["CashIn" .. i] = trans
        i = i + 1
    end

    i = 1
    for _, trans in ipairs(transactions.CashExpense) do
        ini.transactions["CashOut" .. i] = trans
        i = i + 1
    end

    local success = inicfg.save(ini, IniFileName)

    
end

--------------Load Transactions--------------
local function loadTransactions()
    local loadedIni = inicfg.load(nil, IniFileName)
    if loadedIni and loadedIni.transactions then
        -- Сбрасываем таблицы, но не сам объект transactions
        transactions.BankWithdrawals = {}
        transactions.DepositWithdrawals = {}
        transactions.DepositGive = {}
        transactions.BankWithdrawGive = {}
        transactions.PlayerReceived = {}
        transactions.PlayerSent = {}  
        transactions.CashExpense = {}
        transactions.CashIncome = {}

        for k, v in pairs(loadedIni.transactions) do
            if k:match("^Bank%d+$") then
                table.insert(transactions.BankWithdrawals, v)
            elseif k:match("^Dep%d+$") then
                table.insert(transactions.DepositWithdrawals, v)
            elseif k:match("^BankGive%d+$") then
                table.insert(transactions.BankWithdrawGive, v)
            elseif k:match("^Recv%d+$") then
                table.insert(transactions.PlayerReceived, v)
            elseif k:match("^Sent%d+$") then
                table.insert(transactions.PlayerSent, v)

            elseif k:match("^Depp%d+$") then
                table.insert(transactions.DepositGive, v)

            elseif k:match("^CashIn%d+$") then
                table.insert(transactions.CashIncome, v)

            elseif k:match("^CashOut%d+$") then
                table.insert(transactions.CashExpense, v)
            end
        end
        print("Итого загружено: Банк(снятие)=" .. #transactions.BankWithdrawals .. ", Депозит=" .. #transactions.DepositWithdrawals .. ", Банк(прибавление)=" .. #transactions.BankWithdrawGive .. ", Получено=" .. #transactions.PlayerReceived .. ", Отправлено=" .. #transactions.PlayerSent)
    else
        print("Не удалось загрузить или нет секции [transactions] в " .. IniFileName)
    end
end




---------------ALL unical dates-----------------
local function getAllUniqueDates(incomeLists, expenseLists)
    local dates = {}
    local seen = {}

    -- Доходы
    for _, list in ipairs(incomeLists) do
        for _, trans in ipairs(list) do
            local date = trans:match("%[(%d%d%d%d%-%d%d%-%d%d)%s%d%d:%d%d:%d%d%]")
            if date and not seen[date] then
                table.insert(dates, date)
                seen[date] = true
            end
        end
    end

    -- Расходы
    for _, list in ipairs(expenseLists) do
        for _, trans in ipairs(list) do
            local date = trans:match("%[(%d%d%d%d%-%d%d%-%d%d)%s%d%d:%d%d:%d%d%]")
            if date and not seen[date] then
                table.insert(dates, date)
                seen[date] = true
            end
        end
    end

    table.sort(dates)

    return dates
end

--------------------Get Transactions By Date-----------------
local function getTransactionsByDateWithTimeOnly(transactionList, date)
    local filtered = {}
    if not transactionList then
        print("Ошибка: transactionList is nil")
        return filtered -- Пустая таблица, если список не существует
    end
    local escapedDate = date:gsub("([%-])", "%%%1")
    for _, trans in ipairs(transactionList) do
        if trans:match("%[" .. escapedDate .. "%s%d%d:%d%d:%d%d%]") then
            local time = trans:match("%[.-%s(%d%d:%d%d:%d%d)%]")
            local rest = trans:match("%[%d%d%d%d%-%d%d%-%d%d%s%d%d:%d%d:%d%d%] (.+)")
            if time and rest then
                local formatted = string.format("[%s] %s", time, rest)
                table.insert(filtered, formatted)
         
            end
        end
    end
    return filtered
end


local function formatWithCommas(number)
    local formatted = tostring(number)
    while true do
        formatted, k = formatted:gsub("^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end



function trackMoney()
    local currentMoney = getPlayerMoney() -- Получаем текущий баланс
    if currentMoney ~= lastMoney then
        local diff = currentMoney - lastMoney -- Считаем разницу
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        if diff > 0 then
            -- Доход (givePlayerMoney)
            local transText = string.format("[%s] Получено наличными: %s", timestamp, formatWithCommas(diff))
            table.insert(transactions.CashIncome, transText)
            saveTransactions()
        elseif diff < 0 then
            -- Расход (takePlayerMoney)
            local absDiff = math.abs(diff) -- Убираем минус для отображения
            local transText = string.format("[%s] Потрачено наличными: %s", timestamp, formatWithCommas(absDiff))
            table.insert(transactions.CashExpense, transText)
            saveTransactions()
        end
        lastMoney = currentMoney -- Обновляем предыдущий баланс
    end
end

lua_thread.create(function()
    while true do
        trackMoney()
        wait(500)
    end
end)






-------------local variables total---------
local totalSalary = ini.data.totalSalary
local totalDeposit = ini.data.totalDeposit
local totalAZ = ini.data.totalAZ

-----------------CheckBox'es----------------------
local chbox_show_menu2 = new.bool(ini.data.chbox_show_menu2)
local chbox_show_total_week = new.bool(ini.data.chbox_show_total_week)

-- --
-- chbox_send_player = false,
-- chbox_send_player_me = false,
-- chbox_give_bank = false,
-- chbox_take_bank = false,
-- chbox_give_deposit = false,
-- chbox_take_deposit = false,


local chbox_show_salary = new.bool(ini.data.chbox_show_salary)
local chbox_show_deposit = new.bool(ini.data.chbox_show_deposit)
local chbox_show_az = new.bool(ini.data.chbox_show_az)
local chbox_show_pdaycount = new.bool(ini.data.chbox_show_pdaycount)

local chbox_show_salary_s = new.bool(ini.data.chbox_show_salary_s)
local chbox_show_deposit_s = new.bool(ini.data.chbox_show_deposit_s)
local chbox_show_az_s = new.bool(ini.data.chbox_show_az_s)
local chbox_show_pdaycount_s = new.bool(ini.data.chbox_show_pdaycount_s)
local chbox_show_pday_timer = new.bool(ini.data.chbox_show_pday_timer) 

local chbox_send_player = new.bool(ini.data.chbox_send_player) 
local chbox_send_player_me = new.bool(ini.data.chbox_send_player_me) 
local chbox_give_bank = new.bool(ini.data.chbox_give_bank) 
local chbox_take_bank = new.bool(ini.data.chbox_take_bank) 
local chbox_give_deposit = new.bool(ini.data.chbox_give_deposit) 
local chbox_take_deposit = new.bool(ini.data.chbox_take_deposit) 

local chbox_autoOpenWindow = new.bool(ini.data.chbox_autoOpenWindow) 




----------------------Inputs-------------------------------
local tokenBot_input = ffi.new("char[256]", u8:encode(ini.data.tokenBot))
local tokenBot = u8:decode(ffi.string(tokenBot_input))
ini.data.tokenBot = u8:decode(ffi.string(tokenBot_input))
inicfg.save(ini, IniFileName)

local ChatIdBot_input = ffi.new("char[256]", u8:encode(ini.data.chatIdBot))
local ChatIdBot = u8:decode(ffi.string(ChatIdBot_input))
ini.data.chatIdBot = u8:decode(ffi.string(ChatIdBot_input))
inicfg.save(ini, IniFileName)

----------------Weeks salary inf---------------
local totalWeekSalary = ini.data.totalWeekSalary
local totalWeekDeposit = ini.data.totalWeekDeposit
local totalWeekAZ = ini.data.totalWeekAZ
local totalWeekPdCount = ini.data.totalWeekPdCount

for i = 0, 6 do
    totalWeekSalary = totalWeekSalary + ini.weeklyEarnings_Salary[i]
    totalWeekDeposit = totalWeekDeposit + ini.weeklyEarnings_Deposit[i]
    totalWeekAZ = totalWeekAZ + ini.weeklyEarnings_az[i]
    totalWeekPdCount = totalWeekPdCount + ini.weeklyEarnings_paydaycount[i]

end

local pday_count = 0


----------------WeekDays--------------
local tWeekdays = {
    [0] = 'Воскресенье',
    [1] = 'Понедельник', 
    [2] = 'Вторник', 
    [3] = 'Среда', 
    [4] = 'Четверг', 
    [5] = 'Пятница', 
    [6] = 'Суббота',
}


----------Remove ColorCodes----------
function removeColorCodes(str)
    return str:gsub("{%x%x%x%x%x%x}", "")
end

-------------Test salary command---------------------
sampRegisterChatCommand("testzps", function()
    samp.onServerMessage(0xFFFFFF, "Общая заработная плата: $1,234")
      samp.onServerMessage(0xFFFFFF, "Текущая сумма на депозите: $264,503,290 {33AA33}(+$154,220)")
    samp.onServerMessage(0xFFFFFF, "Баланс на донат-счет: 4811 AZ {ff6666}(+1 AZ)")
   end)

   -----------------------Test command n2----------------------
   sampRegisterChatCommand("pr", function()
    samp.onServerMessage(0xFFFFFF, "Вы сняли деньги с депозитного счета: $100,000")
   end)



---------------SaveData----------------
function saveData()
    saveTransactions()
    ini.data.chbox_show_menu2 = chbox_show_menu2[0]
    for i = 0, 6 do
        inicfg.save(ini, IniFileName)
    end
end

---------------AutoSave----------------
function autoSave()
    while true do
        wait(60000) 
        saveData() 
    end
end

----------------------Clear Week--------------------
function clearweek()
    lua_thread.create(function()
        while true do
            wait(1000)  -- Проверка каждую секунду
            local currentTime = os.date("%H:%M:%S", os.time())  -- Получаем текущее время
            if currentDay == 0 and currentTime == "23:59:58" then
                print("yes")

                for i = 0, 6 do
                    ini.weeklyEarnings_Salary[i] = 0
                    ini.weeklyEarnings_Deposit[i] = 0
                    ini.weeklyEarnings_az[i] = 0
                    ini.weeklyEarnings_paydaycount[i] = 0
                end
                inicfg.save(ini, IniFileName)
  

            end
        end
    end)
end

clearweek()


function clearpayday()
            for i = 0, 6 do
                    ini.weeklyEarnings_Salary[i] = 0
                    ini.weeklyEarnings_Deposit[i] = 0
                    ini.weeklyEarnings_az[i] = 0
                    ini.weeklyEarnings_paydaycount[i] = 0
                    inicfg.save(ini, IniFileName)
                end
            inicfg.save(ini, IniFileName)
            end




----------Other variables-----------------
local tab = ""
local give_payday_button = ""

local selectedTab_doxod = nil
local selectedTab_rasxod = nil

local money = getPlayerMoney()

local nowTime = os.date("%H:%M:%S", os.time())
------------------Calculate Total amout----------------------
local function calculateTotalAmount(transactionList, date)
    local total = 0
    if not transactionList then
        print("Ошибка: transactionList is nil")
        return total
    end
    print("Считаем сумму для " .. date .. ", транзакций: " .. #transactionList)
    local escapedDate = date:gsub("([%-])", "%%%1")
    for _, trans in ipairs(transactionList) do
        print("Проверяем: " .. trans)
        if trans:match("%[" .. escapedDate .. "%s%d%d:%d%d:%d%d%]") then
            local amountStr = trans:match("в размере: ([%d,]+)$") or trans:match("на сумму: ([%d,]+)$")
            if amountStr then
                print("Найдена сумма: " .. amountStr)
                local cleanedAmount = amountStr:gsub("[,%s]", "")
                local amount = tonumber(cleanedAmount)
                if amount then
                    total = total + amount
                    print("Добавлено к общей сумме: " .. amount)
                else
                    print("Ошибка преобразования в число: " .. cleanedAmount)
                end
            else
                print("Сумма не найдена в строке: " .. trans)
            end
        else
            print("Дата не совпадает: " .. trans)
        end
    end
    print("Итоговая сумма: " .. total)
    return total
end

-----------------Next PayDay timer--------------------
function getNextPayDay()
    local currentTime = os.time()
    local currentMinute = tonumber(os.date("%M", currentTime))
    local nextPayDay

    if currentMinute < 30 then
        
        nextPayDay = os.time{year=os.date("%Y"), month=os.date("%m"), day=os.date("%d"), hour=os.date("%H"), min=30, sec=0}
    else
        nextPayDay = os.time{year=os.date("%Y"), month=os.date("%m"), day=os.date("%d"), hour=os.date("%H")+1, min=0, sec=0}
    end

    return nextPayDay
end

------------------------Update payday timer------------------
function updatePayDayTimer()
    local nextPayDay = getNextPayDay()  -- Здесь мы вызываем функцию, а не просто ссылку на неё
    local timeLeft = nextPayDay - os.time()  -- Теперь вычисляем оставшееся время
    local minutes = math.floor(timeLeft / 60)
    local seconds = timeLeft % 60
    
    return minutes, seconds
end

----------------Unix str calc----------------------
function getStrDate(unixTime)
    local tMonths = {'января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'}
    local day = tonumber(os.date('%d', unixTime))
    local month = tMonths[tonumber(os.date('%m', unixTime))]
    local weekday = tWeekdays[tonumber(os.date('%w', unixTime))]
    return string.format('%s, %s %s', weekday, day, month)
end




-------------------------PARSING SYSTEM--------------------------
function samp.onServerMessage(color, text)
    paydayBuffer = paydayBuffer or {}
    table.insert(paydayBuffer, text)


    local bank = text:match("Текущая сумма в банке: %$([%d,]+)")
    if bank then
        initialBank = tonumber((bank:gsub(",", "")))
        saveData()
    end

    local deposit = text:match("Текущая сумма на депозите: %$([%d,]+)")
    if deposit then
        initialDeposit = tonumber((deposit:gsub(",", "")))
        saveData()
    end

    local az = text:match("Баланс на донат%-счет: (%d+) AZ")
    if az then
        initialAZ = tonumber(az)
        saveData()
    end

    if #paydayBuffer >= 5 then
        local fullText = table.concat(paydayBuffer, "\n")

        local salary = fullText:match("Общая заработная плата: %$([%d,]+)")
        if salary then
            totalSalary = totalSalary + tonumber((salary:gsub(",", "")))

            pday_count = pday_count + 1

            local currentDay = tonumber(os.date("%w")) -- 0 = Воскресенье, 6 = Суббота
            ini.weeklyEarnings_paydaycount[currentDay] = (ini.weeklyEarnings_paydaycount[currentDay] or 0) + 1
            


            local currentDay = tonumber(os.date("%w")) -- 0 = Воскресенье, 6 = Суббота
            ini.weeklyEarnings_Salary[currentDay] = ini.weeklyEarnings_Salary[currentDay] + (tonumber((salary:gsub(",", ""))) or 0)
            inicfg.save(ini, IniFileName)
        end

        local depositBonus = fullText:match("Текущая сумма на депозите: %$[%d,]+ %b{}%(%+%$([%d,]+)%)")
        if depositBonus then
            totalDeposit = totalDeposit + tonumber((depositBonus:gsub(",", "")))
            local currentDay = tonumber(os.date("%w")) -- 0 = Воскресенье, 6 = Суббота
 
            ini.weeklyEarnings_Deposit[currentDay] = ini.weeklyEarnings_Deposit[currentDay] + (tonumber((depositBonus:gsub(",", ""))) or 0)
            inicfg.save(ini, IniFileName)
        end

        local azBonus = fullText:match("Баланс на донат%-счет: %d+ AZ %b{}%(%+(%d+) AZ%)")
        if azBonus then
            totalAZ = totalAZ + tonumber(azBonus)
            local currentDay = tonumber(os.date("%w")) -- 0 = Воскресенье, 6 = Суббота
            ini.weeklyEarnings_az[currentDay] = ini.weeklyEarnings_az[currentDay] + (tonumber((azBonus:gsub(",", ""))) or 0)
            inicfg.save(ini, IniFileName)
        end

        saveData()
            paydayBuffer = {}

    end
    local timestamp = os.date("%Y-%m-%d %H:%M:%S") -- Полная дата и время для хранения

    -- Снятие с банка
    local bankWithdraw = text:match("%[Информация%] {FFFFFF}Вы сняли со своего банковского счета %$([%d,]+)")
    if bankWithdraw then
        local cleanedAmount = bankWithdraw:gsub("[,%s]", "")
        local amount = tonumber(cleanedAmount)
        if amount then

            if chbox_take_bank[0] then
                telegram.setConfig(ChatIdBot,tokenBot)
                telegram.sendMessage(string.format(
                "**Снятие с банка**\n" ..
                "**Сумма:** `$%s`\n" ..
                "**Время:** `%s`",
                formatWithCommas(amount), timestamp
            ))
        end

            bankWithdrawals = (bankWithdrawals or 0) + amount
            local transText = string.format("[%s] Вы сняли с банковского счета в размере: %s", timestamp, formatWithCommas(amount))
            table.insert(transactions.BankWithdrawals, transText)
            saveTransactions()
            sampAddChatMessage("Снято с банка: " .. formatWithCommas(amount), -1)
        end
    end

    -- Снятие с депозита
    local depositWithdraw = text:match("Вы сняли деньги с депозитного счета %$([%d,]+)")
    if depositWithdraw then
        local cleanedAmount = depositWithdraw:gsub("[,%s]", "")
        local amount = tonumber(cleanedAmount)
        if amount then

            if chbox_take_deposit[0] then
                telegram.setConfig(ChatIdBot,tokenBot)
                telegram.sendMessage(string.format(
                "**Снятие с депозита**\n" ..
                "**Сумма:** `$%s`\n" ..
                "**Время:** `%s`",
                formatWithCommas(amount), timestamp
            ))
        end

            depositWithdrawals = (depositWithdrawals or 0) + amount
            local transText = string.format("[%s] Вы сняли с депозитного счета в размере: %s", timestamp, formatWithCommas(amount))
            table.insert(transactions.DepositWithdrawals, transText)
            saveTransactions()
            sampAddChatMessage("Снято с депозита: " .. formatWithCommas(amount), -1)
        end
    end

     -- Пополнение  депозита
     local deposiGivee = text:match("Вы положили на свой депозитный счет %$([%d,]+)")
     if deposiGivee then
         local cleanedAmount = deposiGivee:gsub("[,%s]", "")
         local amount = tonumber(cleanedAmount)
         if amount then
            deposiGiveeS = (deposiGiveeS or 0) + amount
             local transText = string.format("[%s] Вы положили на свой депозитный счет | %s", timestamp, formatWithCommas(amount))
             
             if chbox_give_deposit[0] then
                telegram.setConfig(ChatIdBot,tokenBot)
                telegram.sendMessage(string.format(
                "**Пополнение депозита**\n" ..
                "**Сумма:** `$%s`\n" ..
                "**Время:** `%s`",
                formatWithCommas(amount), timestamp
            ))
        end

             table.insert(transactions.DepositGive, transText)
             saveTransactions()
             sampAddChatMessage("Положено : " .. formatWithCommas(amount), -1)
         end
     end

    -- Пополнение банка
    local bankDeposit = text:match("Вы положили на свой банковский счет %$([%d,]+)")
    if bankDeposit then
        local cleanedAmount = bankDeposit:gsub("[,%s]", "")
        local amount = tonumber(cleanedAmount)
        if amount then

            if chbox_give_bank[0] then
                telegram.setConfig(ChatIdBot,tokenBot)
                telegram.sendMessage(string.format(
                "**Пополнение счета**\n" ..
                "**Сумма:** `$%s`\n" ..
                "**Время:** `%s`",
                formatWithCommas(amount), timestamp
            ))
        end


            bankDeposits = (bankDeposits or 0) + amount
            local transText = string.format("[%s] Вы пополнили свой банковский счет на сумму: %s", timestamp, formatWithCommas(amount))
            table.insert(transactions.BankWithdrawGive, transText)
            saveTransactions()
            sampAddChatMessage("Положено на банковский счёт: " .. formatWithCommas(amount), -1)
        end
    end

    
    local playerReceivedNew = text:match("Вам поступил перевод на ваш счет в размере %$([%d,]+) от жителя ([%w_]+)%(%d+%)")
    if playerReceivedNew then
        local amountStr, playerName = text:match("Вам поступил перевод на ваш счет в размере %$([%d,]+) от жителя ([%w_]+)%(%d+%)")
        if amountStr and playerName then
            local cleanedAmount = amountStr:gsub("[,%s]", "")
            local amount = tonumber(cleanedAmount)
            if amount then
                local transText = string.format("[%s] Поступление на банк от %s | : %s", timestamp, playerName, formatWithCommas(amount))
                
             if chbox_send_player_me[0] then
                    telegram.setConfig(ChatIdBot,tokenBot)
                    telegram.sendMessage(string.format(
                    "**Пополнение счета**\n" ..
                    "**Отправитель:** `%s`\n" ..
                    "**Сумма:** `$%s`\n" ..
                    "**Время:** `%s`",
                    playerName, formatWithCommas(amount), timestamp
                ))
            end
            
                
                table.insert(transactions.PlayerReceived, transText)
                saveTransactions()
                sampAddChatMessage("Получено от игрока " .. playerName .. ": " .. formatWithCommas(amount), -1)
            end
        end
    end

    
    local playerSentNew = text:match("{FFFFFF}Вы перевели %$([%d,]+) игроку ([%w_]+)%(%d+%) на счет")
    if playerSentNew then
        local amountStr, playerName = text:match("{FFFFFF}Вы перевели %$([%d,]+) игроку ([%w_]+)%(%d+%) на счет")
        if amountStr and playerName then
            local cleanedAmount = amountStr:gsub("[,%s]", "")
            local amount = tonumber(cleanedAmount)
            if amount then

                local transText = string.format("[%s] Вы перевели игроку %s сумму в размере: %s", timestamp, playerName, formatWithCommas(amount))
                

        if chbox_send_player[0] then 
                telegram.setConfig(ChatIdBot,tokenBot)
                telegram.sendMessage(string.format(
                "**Перевод средств**\n" ..
                "**Получатель:** `%s`\n" ..
                "**Сумма:** `$%s`\n" ..
                "**Время:** `%s`",
                playerName, formatWithCommas(amount), timestamp
            ))
        end
                table.insert(transactions.PlayerSent, transText)
                saveTransactions()
                sampAddChatMessage("Отправлено игроку " .. playerName .. ": " .. formatWithCommas(amount), -1)
            end
        end
    end

    

end


local finalSalary, finalDeposit
function updatePaydayData()
local currentDay = tonumber(os.date("%w")) 

if currentDay == 0 then
    -- Если сегодня воскресенье
    todaySalary = ini.weeklyEarnings_Salary[0]
    todayDeposit = ini.weeklyEarnings_Deposit[0]
    todayAZ = ini.weeklyEarnings_az[0]
    todayPaydayCount = ini.weeklyEarnings_paydaycount[0]
    
    finalSalary = ini.weeklyEarnings_Salary[0] - (bankWithdrawals or 0)
    finalDeposit = ini.weeklyEarnings_Deposit[0] - (depositWithdrawals or 0)

else
    -- Остальные дни недели (1-6)
    todaySalary = ini.weeklyEarnings_Salary[currentDay]
    todayDeposit = ini.weeklyEarnings_Deposit[currentDay]
    todayAZ = ini.weeklyEarnings_az[currentDay]
    todayPaydayCount = ini.weeklyEarnings_paydaycount[currentDay]

end
end


------------------------Inf small window-------------------
local show = imgui.new.bool(ini.data.chbox_show_menu2)
local posX, posY = ini.data.pos_x or 100, ini.data.pos_y or 100 
imgui.OnFrame(function() 
    return show[0]  
end, function()
    if posX and posY then
        imgui.SetNextWindowPos(imgui.ImVec2(posX, posY), imgui.Cond.Always)
    end
    imgui.Begin('Window Two', show, imgui.WindowFlags.NoResize  + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoTitleBar)
    updatePaydayData()
    local minutes, seconds = updatePayDayTimer()
    imgui.PushFont(font[25])
    imgui.CenterText(nowTime)
    imgui.PopFont()
    imgui.SetCursorPosY(38)
    imgui.CenterText(u8(getStrDate(os.time())))
    imgui.Separator()

    if chbox_show_salary_s[0] then 
    imgui.Text(u8(string.format("Зарплата : %s", formatWithCommas(todaySalary))))
    end

    if chbox_show_deposit_s[0] then 
    imgui.Text(u8(string.format("Депозит : %s", formatWithCommas(todayDeposit))))
    end

    if chbox_show_az_s[0] then
    imgui.Text(u8(string.format("AZ-COINS : %s", (todayAZ))))
    end

    if chbox_show_pdaycount_s[0] then 
    imgui.Text(u8(string.format("Кол-во Pay-Day'ев : %s", (todayPaydayCount))))
    end

    if chbox_show_pday_timer[0] then 
    imgui.Text(u8(string.format("До PayDay: %02d мин %02d сек", minutes, seconds)))
    end

    imgui.End()
end).HideCursor = true


if chbox_show_menu2[0] then
    show[0] = not show[0]
end






local selectedBankGiveDate = new.int(0)
local selectedBankWithdrawDate = new.int(0)



local tab = 1
local changepos = false

local settingsPage = nil


imgui.OnFrame(function() return WinState[0] end, function(player)
    local servername = sampGetCurrentServerName():gsub("Arizona Role Play | ", "") -- Исправлено дублирование переменной
    local nick = sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))

    imgui.SetNextWindowPos(imgui.ImVec2(500, 500), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(600, 500), imgui.Cond.Always)
    
    imgui.Begin('##Window', WinState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

    imgui.BeginChild('TitleChild', imgui.ImVec2(578, 40), true, imgui.WindowFlags.NoScrollbar)     
    imgui.PushFont(font[25])
    imgui.SetCursorPosY(8)
    imgui.CenterText("Finance Helper")
    imgui.PopFont()
    imgui.EndChild()

    imgui.BeginChild('Buttons', imgui.ImVec2(130, 0), true, imgui.WindowFlags.NoScrollbar) 
    imgui.SetCursorPosX(10)
    if imgui.Button(u8'Главная', imgui.ImVec2(110, 50)) then tab = 1 end
    imgui.SetCursorPosX(10)
    if imgui.Button(u8'Доходы', imgui.ImVec2(110, 50)) then tab = 2 end
    imgui.SetCursorPosX(10)
    if imgui.Button(u8'Расходы', imgui.ImVec2(110, 50)) then tab = 3 end
    imgui.SetCursorPosX(10)
    if imgui.Button(u8'Настройки', imgui.ImVec2(110, 50)) then tab = 4 end
    imgui.EndChild()

    imgui.SameLine()

    imgui.BeginChild('MainChild', imgui.ImVec2(440, 0), true, imgui.WindowFlags.NoScrollbar)
    local minutes, seconds = updatePayDayTimer()

    if tab == 1 then 
        imgui.PushFont(font[25])
        imgui.SetCursorPosY(8)
        imgui.CenterText(u8"Главное меню")
        imgui.PopFont()
        imgui.Separator()
        imgui.BulletText(u8"Ваш ник нейм: "..nick)
        imgui.BulletText(u8"Сервер: "..servername)
        imgui.BulletText(u8"Наличные деньги: $"..formatWithCommas(getPlayerMoney()))
        imgui.BulletText(u8(string.format("До следующего PayDay: %02d мин %02d сек", minutes, seconds)))

    elseif tab == 2 then
        if imgui.Button(u8"PayDay", imgui.ImVec2(130, 30)) then 
            selectedTab_doxod = "payday"
        end
        imgui.SameLine()
        if imgui.Button(u8"Банк переводы", imgui.ImVec2(130, 30)) then 
            selectedTab_doxod = "bank"
        end
        imgui.SameLine()
        if imgui.Button(u8"Наличные деньги", imgui.ImVec2(130, 30)) then 
            selectedTab_doxod = "cash"
        end
        imgui.Separator()

        if selectedTab_doxod == "payday" then
            if chbox_show_total_week[0] then
                imgui.Text(u8"Общий заработок | $%s | Депозит: $%s | Az-coins: %s ", formatWithCommas(totalWeekSalary), formatWithCommas(totalWeekDeposit), formatWithCommas(totalWeekAZ))
            end
            imgui.Separator()
            for i = 1, 6 do
                imgui.Text(u8(tWeekdays[i]..":"))
                if chbox_show_salary[0] then
                    imgui.Text(u8(string.format("Зарплата : %s", formatWithCommas(ini.weeklyEarnings_Salary[i]))))
                end
                if chbox_show_deposit[0] then
                    imgui.Text(u8(string.format("Депозит : %s", formatWithCommas(ini.weeklyEarnings_Deposit[i]))))
                end
                if chbox_show_az[0] then
                    imgui.Text(u8(string.format("AZ-COINS : %s", formatWithCommas(ini.weeklyEarnings_az[i]))))
                end
                imgui.Text(u8(string.format("Кол-во PayDay'ев : %s", formatWithCommas(ini.weeklyEarnings_paydaycount[i]))))
                imgui.Separator()
            end

            -- Воскресенье
            imgui.Text(u8(tWeekdays[0]..":"))
            if chbox_show_salary[0] then
                imgui.Text(u8(string.format("Зарплата : %s", formatWithCommas(ini.weeklyEarnings_Salary[0]))))
            end
            if chbox_show_deposit[0] then
                imgui.Text(u8(string.format("Депозит : %s", formatWithCommas(ini.weeklyEarnings_Deposit[0]))))
            end
            if chbox_show_az[0] then
                imgui.Text(u8(string.format("AZ-COINS : %s", formatWithCommas(ini.weeklyEarnings_az[0]))))
            end
            imgui.Text(u8(string.format("Кол-во PayDay'ев : %s", formatWithCommas(ini.weeklyEarnings_paydaycount[0]))))

        elseif selectedTab_doxod == "bank" then
            local incomeLists = {transactions.BankWithdrawGive, transactions.PlayerReceived}
            local incomeDates = getAllUniqueDates(incomeLists, {})
            if #incomeDates > 0 then
                local dateItems = new['const char*'][#incomeDates]()
                for i, date in ipairs(incomeDates) do
                    dateItems[i-1] = "                                       " .. date
                end
                imgui.SetNextItemWidth(410)
                imgui.Combo(u8"##ChangeDate1", selectedBankGiveDate, dateItems, #incomeDates)
                imgui.Separator()
                local selectedDate = incomeDates[selectedBankGiveDate[0] + 1]
                if selectedDate then
                    local totalIncome = 0
                    totalIncome = totalIncome + calculateTotalAmount(transactions.BankWithdrawGive, selectedDate)
                    totalIncome = totalIncome + calculateTotalAmount(transactions.PlayerReceived, selectedDate)
                    totalIncome = totalIncome + calculateTotalAmount(transactions.DepositGive, selectedDate)
                    imgui.SetCursorPosX(125)
                    imgui.Text(u8(string.format("Общий доход за %s: %s", selectedDate, formatWithCommas(totalIncome))))
                    imgui.Separator()
            
   

                    -- Пополнение банковского счета
                    local bankGiveFiltered = getTransactionsByDateWithTimeOnly(transactions.BankWithdrawGive, selectedDate)
                    for _, trans in ipairs(bankGiveFiltered) do
                        imgui.Text(u8(trans))
                    end

                    -- Получено от игроков
                    local receivedFiltered = getTransactionsByDateWithTimeOnly(transactions.PlayerReceived, selectedDate)
                    for _, trans in ipairs(receivedFiltered) do
                        imgui.Text(u8(trans))
                    end

                    local DepositGivees = getTransactionsByDateWithTimeOnly(transactions.DepositGive, selectedDate)
                    for _, trans in ipairs(DepositGivees) do
                        imgui.Text(u8(trans))
                    end
                else
                    imgui.Text(u8"Дата не выбрана")
                end
            else
                imgui.Text(u8"Нет записей о доходах")
            end

        elseif selectedTab_doxod == "cash" then
            local cashLists = {transactions.CashIncome} -- Убрано дублирование
            local cashDates = getAllUniqueDates(cashLists, {})
            if #cashDates > 0 then
                local dateItems = new['const char*'][#cashDates]()
                for i, date in ipairs(cashDates) do
                    dateItems[i-1] = "                                       " .. date
                end
                imgui.SetNextItemWidth(410)
                imgui.Combo(u8"##ChangeDateCashG", selectedBankGiveDate, dateItems, #cashDates)
                imgui.Separator()
                local selectedDate = cashDates[selectedBankGiveDate[0] + 1]
                if selectedDate then
                    local expenseFiltered = getTransactionsByDateWithTimeOnly(transactions.CashIncome, selectedDate)
                    for _, trans in ipairs(expenseFiltered) do
                        -- Извлекаем сумму дохода из текста транзакции
                        local amountStr = trans:match("Получено наличными: ([%d,]+)")
                        if amountStr then
                            local cleanedAmount = amountStr:gsub("[,%s]", "") -- Убираем запятые
                            local amount = tonumber(cleanedAmount)
                            local currentBalance = getPlayerMoney() -- Текущий баланс игрока

                            -- Проверяем, совпадает ли сумма дохода с текущим балансом
                            if amount ~= currentBalance then
                                imgui.Text(u8(trans)) -- Показываем транзакцию, только если сумма не равна балансу
                            end
                        else
                            imgui.Text(u8(trans)) -- Если сумму не удалось извлечь, показываем транзакцию
                        end
                    end
                else
                    imgui.Text(u8"Дата не выбрана")
                end
            else
                imgui.Text(u8"Нет записей о наличных операциях")
            end
        end -- Закрываем if selectedTab_doxod

    elseif tab == 3 then 
        if imgui.Button(u8"Банк переводы", imgui.ImVec2(200, 30)) then 
            selectedTab_rasxod = "bank"
        end
        imgui.SameLine()
        if imgui.Button(u8"Наличные деньги", imgui.ImVec2(200, 30)) then 
            selectedTab_rasxod = "cash"
        end
        imgui.Separator()

        if selectedTab_rasxod == "bank" then
            local expenseLists = {transactions.BankWithdrawals, transactions.DepositWithdrawals, transactions.PlayerSent}
            local expenseDates = getAllUniqueDates({}, expenseLists)
            if #expenseDates > 0 then
                local dateItems = new['const char*'][#expenseDates]()
                for i, date in ipairs(expenseDates) do
                    dateItems[i-1] = "                                       " .. date
                end
                imgui.SetNextItemWidth(410)
                imgui.Combo(u8"##ChangeDate2", selectedBankWithdrawDate, dateItems, #expenseDates)
                imgui.Separator()
                local selectedDate = expenseDates[selectedBankWithdrawDate[0] + 1]
                if selectedDate then
                    local totalExpense = 0
                    totalExpense = totalExpense + calculateTotalAmount(transactions.BankWithdrawals, selectedDate)
                    totalExpense = totalExpense + calculateTotalAmount(transactions.DepositWithdrawals, selectedDate)
                    totalExpense = totalExpense + calculateTotalAmount(transactions.PlayerSent, selectedDate)
                    imgui.SetCursorPosX(125)
                    imgui.Text(u8(string.format("Общий расход за %s: %s", selectedDate, formatWithCommas(totalExpense))))
                    imgui.Separator()
                    -- Снятие с банковского счета
                    local bankWithdrawFiltered = getTransactionsByDateWithTimeOnly(transactions.BankWithdrawals, selectedDate)
                    for _, trans in ipairs(bankWithdrawFiltered) do
                        imgui.Text(u8(trans))
                    end

                    
                    local depositWithdrawFiltered = getTransactionsByDateWithTimeOnly(transactions.DepositWithdrawals, selectedDate)
                    for _, trans in ipairs(depositWithdrawFiltered) do
                        imgui.Text(u8(trans))
                    end

                    -- Перевод игрокам
                    local sentFiltered = getTransactionsByDateWithTimeOnly(transactions.PlayerSent, selectedDate)
                    for _, trans in ipairs(sentFiltered) do
                        imgui.Text(u8(trans))
                    end
                else
                    imgui.Text(u8"Дата не выбрана")
                end
            else
                imgui.Text(u8"Нет записей о расходах")
            end

        elseif selectedTab_rasxod == "cash" then
            local cashLists = {transactions.CashIncome, transactions.CashExpense}
            local cashDates = getAllUniqueDates(cashLists, {})
            if #cashDates > 0 then
                local dateItems = new['const char*'][#cashDates]()
                for i, date in ipairs(cashDates) do
                    dateItems[i-1] = "                                       " .. date
                end
                imgui.SetNextItemWidth(410)
                imgui.Combo(u8"##ChangeDateCash", selectedBankGiveDate, dateItems, #cashDates)
                imgui.Separator()
                local selectedDate = cashDates[selectedBankGiveDate[0] + 1]
                if selectedDate then
                    local expenseFiltered = getTransactionsByDateWithTimeOnly(transactions.CashExpense, selectedDate)
                    for _, trans in ipairs(expenseFiltered) do
                        imgui.Text(u8(trans))
                    end
                else
                    imgui.Text(u8"Дата не выбрана")
                end
            else
                imgui.Text(u8"Нет записей о наличных операциях")
            end
        end -- Закрываем if selectedTab_rasxod

    elseif tab == 4 then -- Настройки
        if imgui.Button(u8"PayDay", imgui.ImVec2(130, 30)) then 
            selectedTab_doxod = "settings_payday"
        end
        imgui.SameLine()
        if imgui.Button(u8"Общие настройки", imgui.ImVec2(130, 30)) then 
            selectedTab_doxod = "settings_all"
        end
        imgui.SameLine()
        if imgui.Button(u8"Банк и переводы", imgui.ImVec2(130, 30)) then 
            selectedTab_doxod = "settings_bank"
        end
        imgui.Separator()

        if selectedTab_doxod == "settings_payday" then 
            if not settingsPage then settingsPage = 1 end
            local maxPages = 2

            if settingsPage == 1 then
                imgui.CenterText(u8"Настройки доп.окна с информацией (Страница 1)")
                imgui.Separator()
                if imgui.Checkbox(u8"Включить окно с дополнительной информацией", chbox_show_menu2) then
                    ini.data.chbox_show_menu2 = chbox_show_menu2[0]
                    show[0] = chbox_show_menu2[0] 
                    saveData()
                end
                imgui.Checkbox(u8"Показывать доход с зарплаты", chbox_show_salary_s)
                imgui.Checkbox(u8"Показывать доход с депозита", chbox_show_deposit_s)
                imgui.Checkbox(u8"Показывать доход с Аз-Коинов", chbox_show_az_s)
                imgui.Checkbox(u8"Показывать кол-во PayDay'ев ", chbox_show_pdaycount_s)
                imgui.Checkbox(u8"Показывать время до PayDay'я ", chbox_show_pday_timer)

                ini.data.chbox_show_salary_s = chbox_show_salary_s[0]
                ini.data.chbox_show_deposit_s = chbox_show_deposit_s[0]
                ini.data.chbox_show_az_s = chbox_show_az_s[0]
                ini.data.chbox_show_pdaycount_s = chbox_show_pdaycount_s[0]
                ini.data.chbox_show_pday_timer = chbox_show_pday_timer[0]
                inicfg.save(ini, IniFileName)

                if imgui.Button(u8"Сменить положение доп.окна") then 
                    changepos = true
                    WinState[0] = false
                end
            elseif settingsPage == 2 then
                imgui.CenterText(u8"Основые настроки PayDay'я")
                imgui.Separator()
                imgui.Checkbox(u8"Показывать доход с зарплаты", chbox_show_salary)
                imgui.Checkbox(u8"Показывать доход с депозита", chbox_show_deposit)
                imgui.Checkbox(u8"Показывать доход с Аз-Коинов", chbox_show_az)
                imgui.Checkbox(u8"Показывать кол-во PayDay'ев ", chbox_show_pdaycount)
                imgui.Checkbox(u8"Показывать общий доход с PayDay'ев ", chbox_show_total_week)
                if imgui.Button(u8"Очистить данные", imgui.ImVec2(200, 30)) then  
                    sampAddChatMessage("[FinanceHelper] Данные о PayDay очищены!", 0x27AE60) 
                    clearpayday() 
                end

                ini.data.chbox_show_salary_s = chbox_show_salary[0]
                ini.data.chbox_show_deposit_s = chbox_show_deposit[0]
                ini.data.chbox_show_az_s = chbox_show_az[0]
                ini.data.chbox_show_pdaycount_s = chbox_show_pdaycount[0]
                ini.data.chbox_show_total_week = chbox_show_total_week[0]
                inicfg.save(ini, IniFileName)
            end

            imgui.Separator()
            imgui.CenterText(u8(string.format("Страница %d/%d", settingsPage, maxPages)))
            imgui.Separator()
            imgui.SetCursorPosX(185)
            if imgui.Button(faicons("ARROW_LEFT"), imgui.ImVec2(30, 30)) then 
                settingsPage = 1
            end
            imgui.SameLine()
            imgui.SetCursorPosX(235)
            if imgui.Button(faicons("ARROW_RIGHT"), imgui.ImVec2(30, 30)) then 
                settingsPage = 2 
            end

        elseif selectedTab_doxod == "settings_all" then 
                imgui.Text("ya lox")
        
            
    
        

        elseif selectedTab_doxod == "settings_bank" then 



                imgui.CenterText(u8"Настройки уведомлений (Страница 1)")
                imgui.Separator()
                imgui.Checkbox(u8"Отправлять уведомление при поступлении средств от игрока", chbox_send_player_me)
                imgui.Checkbox(u8"Отправлять уведомление при отправке средств игроку", chbox_send_player)
                imgui.Checkbox(u8"Отправлять уведомление при пополнении личного счета", chbox_give_bank)
                imgui.Checkbox(u8"Отправлять уведомление при снятии денег с личного счета", chbox_take_bank)
                imgui.Checkbox(u8"Отправлять уведомление при пополнении депозитного счета", chbox_give_deposit)
                imgui.Checkbox(u8"Отправлять уведомление при снятии денег с депозитного счета", chbox_take_deposit)
                imgui.Separator()
                imgui.SetNextItemWidth(410)
                
                imgui.InputText(u8'Введите token бота', tokenBot_input, 256)   
                if imgui.Button(u8"Как получить Token бота", imgui.ImVec2(410, 30)) then 
                    imgui.OpenPopup("Как получить Token бота")
                end
                if imgui.BeginPopup("Как получить Token бота") then
                    imgui.Text(u8"1.Нажимаем на поиск и ищем @BotFather\n2.В поиске выбираем @BotFather\n3.Нажимаем на 'Начать'\n4.Нажимаем на /newbot и вводим имя бота пример 'FinanceHelper'\n5.После вводим имя бота только в конце с приставкой 'bot'. Пример 'FinanceHelperBot'\n6.Получаем токен бота под текстом 'Use this token to access the HTTP API:' ")
                    imgui.EndPopup()
                end
        
                imgui.SetNextItemWidth(410)
                imgui.InputText(u8'Введите ChatID бота', ChatIdBot_input, 256)   
                if imgui.Button(u8"Как получить ChatID", imgui.ImVec2(410, 30)) then 
                    imgui.OpenPopup("Как получить ChatID")
                end
                if imgui.BeginPopup("Как получить ChatID") then
                    imgui.Text(u8"1.Нажимаем на поиск\n2.Ищем бота в поиске с ником '@getmyid_bot'\n3.Нажимаем на 'Начать'\n4.После нажатия бот даст нам наш ChatID.")
                    imgui.EndPopup()
                end
        
  

            -- Сохранение данных (только один раз)
            ini.data.chbox_send_player_me = chbox_send_player_me[0]

            ini.data.chbox_send_player = chbox_send_player[0]
            ini.data.chbox_give_bank = chbox_give_bank[0]
            ini.data.chbox_take_bank = chbox_take_bank[0]
            ini.data.chbox_give_deposit = chbox_give_deposit[0]
            ini.data.chbox_take_deposit = chbox_take_deposit[0]
            ini.data.chatIdBot = u8:decode(ffi.string(ChatIdBot_input))
            ini.data.tokenBot = u8:decode(ffi.string(tokenBot_input))
            inicfg.save(ini, IniFileName)

            -- Кнопки переключения страниц
    --         imgui.Separator()
    --         imgui.CenterText(u8(string.format("Страница %d/%d", settingsPage, maxPages)))
    --         imgui.Separator()
    --         imgui.SetCursorPosX(185)
    --         if imgui.Button(faicons("ARROW_LEFT"), imgui.ImVec2(30, 30)) then 
    --             if settingsPage > 1 then settingsPage = settingsPage - 1 end
    --         end
    --         imgui.SameLine()
    --         imgui.SetCursorPosX(235)
    --         if imgui.Button(faicons("ARROW_RIGHT"), imgui.ImVec2(30, 30)) then 
    --             if settingsPage < maxPages then settingsPage = settingsPage + 1 end
    --         end
        end 
        end

    imgui.EndChild()
    imgui.End()
end)


------------------------------Main Fuction-------------------------
function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    


    if chbox_autoOpenWindow[0] then 
        WinState[0] = true
    end
    show[0] = chbox_show_menu2[0]
    lastMoney = getPlayerMoney()
    loadTransactions()
    lua_thread.create(autoSave)
    sampAddChatMessage("[FinanceHelper 3.0] Скрипт загружен, гангстер! Версия: " .. SCRIPT_VERSION, 0x27AE60)
    
    sampAddChatMessage("[FinanceHelper] Скрипт загружен", 0x27AE60)
    while true do
        wait(0)
        if wasKeyPressed(VK_X) and not sampIsCursorActive() then
            WinState[0] = not WinState[0]
        end

        if changepos then
            posX, posY = getCursorPos() -- Обновляем позицию по курсору
            if isKeyJustPressed(1) then -- VK_LBUTTON = левая кнопка мыши
                changepos = false
                ini.data.pos_x, ini.data.pos_y = posX, posY
                inicfg.save(ini, IniFileName)
                sampAddChatMessage("[FinanceHelper] Позиция сохранена: X=" .. posX .. ", Y=" .. posY, 0x27AE60)
            end
        end
    end
end






-----------------CenterText----------------------
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(width / 2 - calc.x / 2)
    imgui.Text(text)
end



function theme()
    local style = imgui.GetStyle()
    local colors = style.Colors
    style.Alpha = 1;
    style.WindowPadding = imgui.ImVec2(15.00, 15.00);
    style.WindowRounding = 0;
    style.WindowBorderSize = 1;
    style.WindowMinSize = imgui.ImVec2(32.00, 32.00);
    style.WindowTitleAlign = imgui.ImVec2(0.50, 0.50);
    style.ChildRounding = 0;
    style.ChildBorderSize = 1;
    style.PopupRounding = 0;
    style.PopupBorderSize = 1;
    style.FramePadding = imgui.ImVec2(8.00, 7.00);
    style.FrameRounding = 0;
    style.FrameBorderSize = 0;
    style.ItemSpacing = imgui.ImVec2(8.00, 8.00);
    style.ItemInnerSpacing = imgui.ImVec2(10.00, 6.00);
    style.IndentSpacing = 25;
    style.ScrollbarSize = 13;
    style.ScrollbarRounding = 0;
    style.GrabMinSize = 6;
    style.GrabRounding = 0;
    style.TabRounding = 0;
    style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50);
    style.SelectableTextAlign = imgui.ImVec2(0.00, 0.00);
    colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.60, 0.56, 0.56, 1.00);
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.16, 0.16, 0.16, 1.00);
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[imgui.Col.PopupBg] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.Border] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
    colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
    colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.19, 0.19, 0.19, 1.00);
    colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
    colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00);
    colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[imgui.Col.CheckMark] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[imgui.Col.Button] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.32, 0.32, 0.32, 1.00);
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.Header] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.Separator] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.Tab] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.TabHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.TabActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00);
    colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00);
    colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.33, 0.33, 0.33, 0.50);
    colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90);
    colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00);
    colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70);
    colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20);
    colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.35);
end

imgui.OnInitialize(function()
    theme()
    imgui.GetIO().IniFilename = nil
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    iconRanges = imgui.new.ImWchar[3](faicons.min_range, faicons.max_range, 0)
    -- Добавление шрифта для иконок
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(faicons.get_font_data_base85('solid'), 15, config, iconRanges)

    local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    local path = getFolderPath(0x14) .. '\\trebucbd.ttf'
  --  imgui.GetIO().Fonts:Clear() -- Удаляем стандартный шрифт на 14
    -- Добавляем основной шрифт для текста
    imgui.GetIO().Fonts:AddFontFromFileTTF(path, 15.0, nil, glyph_ranges)
    -- дополнительные шрифты
    font[25] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 25.0, nil, glyph_ranges)

    font[40] = imgui.GetIO().Fonts:AddFontFromFileTTF(path, 40.0, nil, glyph_ranges)
end)
