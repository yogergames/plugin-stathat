-- Sample code is MIT licensed, see http://www.coronalabs.com/links/code/license
-- Copyright (C) 2016 Yoger Games AB. All Rights Reserved.


------------------------------------------------------------
-- REPLACE THESE VARIABLES WITH YOUR STATHAT ACCOUNT NAME AND ACCESS TOKEN
-----------------------------------

local USER_KEY = "hello@example.com" -- REPLACE WITH YOUR OWN USER KEY
local ACCESS_TOKEN = nil -- REPLACE WITH YOUR OWN ACCESS TOKEN

-----------------------------------
-- Setup
-----------------------------------
local stathat = require("plugin.stathat")
local widget = require("widget")

display.setDefault( "background", 0.9, 0.9, 0.9 )
local w, h = display.contentWidth,display.contentHeight
-----------------------------------
-- Parameters
-----------------------------------
local statName = "My stat name"
local requestId
local statId
local chart
local logo
local countButton
local totalCountLabel
local totalCountText
local timerId
local statCountMap = {}
local countHasBeenSent = false
-----------------------------------
-- Forward declare functions
-----------------------------------
local StathatCallback
local StathatList
local StathatInfo
local StathatData
local StathatDelete
local RefreshCountButton
-----------------------------------
-- Stathat initialization
-----------------------------------
-- Initialize stathat
local options = {
    api = "ez",
    user_key = USER_KEY,
    token = ACCESS_TOKEN
}
stathat.init(options)


-----------------------------------
-- Stathat callback
-----------------------------------

local function GetStatIdFromList(list)

    for _,item in next,list,nil do
        if (item.name == statName) then
            statId = item.id
            StathatData()
            return
        end
    end
end

local function GetStatIdFromInfo(info)
    statId = info.id
    StathatData()
end

local function GetTotalCount(data)
    local totalCount = 0
    for _,item in next,data[1].points,nil do
        totalCount = totalCount + item.value
    end

    return totalCount
end

local function GetTotalCountLabel()
   return ("Total count 1 hour\n(" .. tostring(statName) ..")")
end

local function GetCountFor(name)
    if statCountMap[name] then
        return statCountMap[name]
    else
        return 0
    end
end

local function RefreshCount(data)
    local nameOfStat = data[1].name
    statCountMap[nameOfStat] = GetTotalCount(data)

    if not totalCountLabel then
        -- Create text label "Total count 1 hour"
        totalCountLabel = display.newText(GetTotalCountLabel(), 0, 0, native.systemFont, 28 )
        totalCountLabel.align = "center"
        totalCountLabel.anchorY = 0
        totalCountLabel.x = w/2
        totalCountLabel.y = countButton.y + countButton.height + 50
        totalCountLabel:setFillColor( 0, 0, 0 )
    end

    local count = GetCountFor(nameOfStat)
    if not totalCountText then
        totalCountText = display.newText(math.round(count*10)*0.1, 0, 0, native.systemFont, 60 )
        totalCountText.anchorY = 0
        totalCountText.x = w/2
        totalCountText.y = totalCountLabel.y + totalCountLabel.height + 10
        totalCountText:setFillColor( 0, 0, 0 )
    else
        totalCountText.text = math.round(count*10)*0.1
    end
end

function StathatCallback(event)

    if event.isError then
        print("Error in request: " .. tostring(event.responseMsg))
        return
    end

    if event.responseType == "count" then
        -- Count was successfully submitted. Let's refresh the chart
        if not statId then StathatInfo()
        else StathatData() end
    elseif event.responseType == "delete" then
        -- handle succesfully deleted message
    elseif event.responseType == "list" then
        GetStatIdFromList(event.payload)
    elseif event.responseType == "info" then
        GetStatIdFromInfo(event.payload)
    elseif event.responseType == "data" then
        RefreshCount(event.payload)

        -- Start a timer to automatically refresh data, currently updated once a minute
        timerId = timer.performWithDelay(1000*60, function() StathatData() end)
    end
end
-----------------------------------
-- Stathat API
-----------------------------------
local function StathatCount()
    requestId = stathat.count(statName, 1, nil, StathatCallback)
    print("stathat count sent. id " .. tostring(requestId))
    countHasBeenSent = true
end

-----------------------------------
-- Stathat Export API - REQUIRES ACCESS_TOKEN to be set
-- Get it at https://www.stathat.com/access
-----------------------------------
function StathatDelete()
    stathat.delete(statId, StathatCallback)
end

function StathatList()
    stathat.list(StathatCallback)
end

function StathatInfo()
    if countHasBeenSent and ACCESS_TOKEN then
        stathat.info(StathatCallback, statName)
    end
end

function StathatData()
    if timerId then
        timer.cancel(timerId)
    end
    stathat.data(statId, nil, "1h", "2m", StathatCallback)
end

-----------------------------------
-- User Interface
-----------------------------------
function RefreshCountButtonLabel()
    countButton:setLabel("Send count 1 for \n\"" .. tostring(statName) .. "\"")
    if totalCountLabel then
        totalCountLabel.text = GetTotalCountLabel()
    end
    if totalCountText then
        totalCountText.text = math.round(GetCountFor(statName)*10)*0.1
    end
    statId = nil
    StathatInfo(StathatCallback, statName)
end

-- Logo
logo = display.newImage("stathat_logo.png", 0,0)
logo.anchorX, logo.anchorY = 0.5, 0
local imageRatio = logo.width / logo.height
logo.width =  0.9 * w
logo.height = logo.width / imageRatio
logo.x, logo.y = w/2, 0

-- Input field for stat name
local textField = native.newTextField( w/2, h/4, w*0.6, 30 )
textField.anchorY = 0
textField.y = logo.y + logo.height + 5
textField:setTextColor( 0.8, 0.8, 0.8 )
textField.hasBackground = true
textField.placeholder = statName
textField.text = statName
textField:resizeFontToFitHeight()
textField.text = ""
textField:addEventListener( "userInput",
    function(event)
        if ( event.phase == "submitted" or event.phase == "editing") then
            statName = event.target.text
            RefreshCountButtonLabel()
        end
    end
    )

countButton = widget.newButton(
    {
        left = 0,
        top = 0,
        id = "countButton",
        onEvent = StathatCount,
        shape = "roundedRect",
        width = textField.width,
        height = 50,
        cornerRadius = 4,
        fontSize = 13,
        fillColor = { default={1,1,1,1}, over={1,1,1,1} },
        strokeColor = { default={0,0,0,1}, over={0.8,0.8,1,1} },
        strokeWidth = 3
    }
)
countButton.anchorY = 0
countButton.x = w/2
countButton.y = textField.y + textField.height + 15
RefreshCountButtonLabel()
