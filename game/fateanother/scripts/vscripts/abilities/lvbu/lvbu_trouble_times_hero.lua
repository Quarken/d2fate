lvbu_trouble_times_hero = class({})
LinkLuaModifier("modifier_trouble_times_hero", "abilities/lvbu/lvbu_trouble_times_hero", LUA_MODIFIER_MOTION_NONE)

function lvbu_trouble_times_hero:GetIntrinsicModifierName()
    return "modifier_trouble_times_hero"
end
--class modifier_trouble_times_hero
modifier_trouble_times_hero = class({})
modifier_trouble_times_hero.IsHidden = function(self) return false end
if IsServer() then
    function modifier_trouble_times_hero:OnCreated(args)   
        --local deadman = PlayerResource:GetPlayerCount()
        self.reduction = 0
        self.dmgbonus = 0         --init
        
        self:StartIntervalThink(0.25)
    end

    function modifier_trouble_times_hero:GetDeadNumber()
        local dednumber = 0
        local alivenumber = 0
        LoopOverPlayers(function(player, playerID, playerHero)
            if playerHero:IsAlive() then
                alivenumber = alivenumber +1
            else
                dednumber = dednumber + 1
            end
        end)
        if alivenumber == 2 then dednumber = 25 end  
        local parent = self:GetParent()
        parent:SetModifierStackCount("modifier_trouble_times_hero", self, dednumber * 2)
        return -dednumber
    end

    function modifier_trouble_times_hero:OnIntervalThink()
        self.dmgreduce = self:GetDeadNumber() * 2
        self.dmgbonus = self.dmgreduce
        
    end

    function modifier_trouble_times_hero:DeclareFunctions()
        return {
            MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
        }
    end

    function modifier_trouble_times_hero:GetModifierIncomingDamage_Percentage()
        return self.dmgreduce
    end
    
end