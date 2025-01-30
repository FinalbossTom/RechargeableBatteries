

local function startRecharge(player, batteries)
    for _i,battery in pairs(batteries) do
        ISTimedActionQueue.add(ISRechargeBattery:new(player, battery));
    end
end

local function isAbleToRecharge(player)
    local Strength = player:getPerkLevel(Perks.Strength)
    if Strength < SandboxVars.RechargeableBatteries.MinimumStrength then return false; end;
    return player:getInventory():contains("BatteryRecharger");
end

RechargeableBatteries = RechargeableBatteries or {}

function RechargeableBatteries.context(playerNum, context, items)

    local items = ISInventoryPane.getActualItems(items);
    if items[1]:getType() ~= "Battery" then return end; -- If we havent targeted a Battery, stop running this script
    local player = getSpecificPlayer(playerNum);
    if isAbleToRecharge(player) ~= true then return end; -- If we dont have the Strength level required, or we are missing a Recharger, stop running the script
    -- if items[1]:getContainer():getType() == "floor" then return end; -- we cant check the distance to items on the floor, so just dont allow it for now.

    local validBatteries = {}
    local validBatteriesCount = 0;
    local targetCharge = 1;
    if SandboxVars.RechargeableBatteries.AllowOvercharge then
        targetCharge = SandboxVars.RechargeableBatteries.OverchargeLimit;
    end
    for _i,item in pairs(items) do
            -- print("Battery at i: " .. _i .. " Charge: " .. item:getDelta())
            if item:getDelta() < targetCharge then
                -- print("Adding " .. _i .. " to Valid Batteries")
                validBatteries[#validBatteries+1] = item;
                validBatteriesCount = validBatteriesCount + 1;
        end
    end


    -- print("Found " .. validBatteriesCount .. " valid Batteries.")
    if validBatteriesCount > 0 then
        local entry;
        local target = {}
        target[#target+1] = validBatteries[1]
        entry = context:addOptionOnTop("Recharge Battery",player,function () startRecharge(player, target) end)


        if validBatteriesCount > 1 then
            local submenu = context:getNew(context);
            context:addSubMenu(entry, submenu);
            local optionOne = submenu:addOption("One",player,function () startRecharge(player, target) end)
            local optionAll = submenu:addOption("All (".. validBatteriesCount .. ")",player, function () startRecharge(player, validBatteries) end)
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Remove(RechargeableBatteries.context)
Events.OnFillInventoryObjectContextMenu.Add(RechargeableBatteries.context)


