

require "TimedActions/ISBaseTimedAction"

---@class ISRechargeBattery : BaseTimedAction
ISRechargeBattery = ISBaseTimedAction:derive("ISRechargeBattery");

function  ISRechargeBattery:isValid()
    return self.battery:getCurrentUsesFloat() <= self.targetCharge + 0.05;
end

function ISRechargeBattery:update()
    if SandboxVars.RechargeableBatteries.DoContinuousCharging then
        self.battery:setCurrentUsesFloat(self.battery:getCurrentUsesFloat() + self.rechargePerTick)
    end
end

function ISRechargeBattery:start()
    self.sound = self.character:playSound("RepairWithWrench")
    self:setActionAnim(CharacterActionAnims.Craft);
end

function ISRechargeBattery:stop()
    self.character:stopOrTriggerSound(self.sound)
    ISBaseTimedAction.stop(self);
end

function ISRechargeBattery:perform()
    self.character:stopOrTriggerSound(self.sound)
    self.battery:setCurrentUsesFloat(0.999);
    ISBaseTimedAction.perform(self)
end


function ISRechargeBattery:new(character, battery, batteryRecharger)
    local o             = {};
    setmetatable(o, self);
    self.__index        = self;
    o.character         = character;
    o.battery           = battery;
    o.batteryRecharger  = batteryRecharger;
    o.strength          = character:getPerkLevel(Perks.Strength)
    o.stopOnWalk        = character:getInventory():contains(battery) == false;
    o.stopOnRun         = true;
    o.maxTime           = 99999;

    o.targetCharge      = 1;
    if SandboxVars.RechargeableBatteries.AllowOvercharge then
        o.targetCharge = SandboxVars.RechargeableBatteries.OverchargeLimit;
    end

    local baseTime = SandboxVars.RechargeableBatteries.CraftTimeBase * 60
    --print("Base Time: " .. baseTime);



    local strengthAdjustment = 0;
    if SandboxVars.RechargeableBatteries.StrengthBasedTime then
        if o.strength > 5 then
            strengthAdjustment = (SandboxVars.RechargeableBatteries.CraftTimeSpeedup * (o.strength - 5));
        end
        if o.strength < 5 then
            strengthAdjustment = (SandboxVars.RechargeableBatteries.CraftTimeSlowdown * (5 - o.strength));
        end
    end
    --print("Strength Multiplier: ".. (o.strength - 5) .. " Adjustment Time: " .. strengthAdjustment)

    local missingDelta = o.targetCharge - battery:getCurrentUsesFloat();
    local deltaAdjustment = baseTime * (o.targetCharge - missingDelta);
    --print("Missing Delta: " .. missingDelta .. " Adjustment Time: " .. deltaAdjustment);

    o.rechargePerTick = o.targetCharge / (baseTime - strengthAdjustment);
    --print("Recharging by " .. o.rechargePerTick .. " per tick.")
    o.maxTime = ((o.targetCharge / o.rechargePerTick) - deltaAdjustment) / 1.25;
    --print("Final Time:" .. o.maxTime)

    return o;
end