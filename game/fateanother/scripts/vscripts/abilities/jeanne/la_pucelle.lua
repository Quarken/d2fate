---@class jeanne_combo_la_pucelle : CDOTA_Ability_Lua
jeanne_combo_la_pucelle = class({})
LinkLuaModifier("modifier_jeanne_la_pucelle", "abilities/jeanne/la_pucelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_la_pucelle_phase1_aura", "abilities/jeanne/la_pucelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_la_pucelle_phase1_pause", "abilities/jeanne/la_pucelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_la_pucelle_phase1_debuff", "abilities/jeanne/la_pucelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_la_pucelle_phase2", "abilities/jeanne/la_pucelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_la_pucelle_fire_thinker", "abilities/jeanne/la_pucelle", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_jeanne_la_pucelle_fire_damage", "abilities/jeanne/la_pucelle", LUA_MODIFIER_MOTION_NONE)

function jeanne_combo_la_pucelle:GetIntrinsicModifierName()
    return "modifier_jeanne_la_pucelle"
end

---@class modifier_jeanne_la_pucelle : CDOTA_Modifier_Lua
modifier_jeanne_la_pucelle = class({})
modifier_jeanne_la_pucelle.IsHidden = function(self) return true end

if IsServer() then
    function modifier_jeanne_la_pucelle:OnCreated(args)
        self.reinc_time = self:GetAbility():GetSpecialValueFor("phase1_duration")
    end

    function modifier_jeanne_la_pucelle:DeclareFunctions()
        return { MODIFIER_PROPERTY_REINCARNATION, MODIFIER_EVENT_ON_DEATH }
    end

    function modifier_jeanne_la_pucelle:ReincarnateTime()
        local parent = self:GetParent()
        self.has_stats = parent:GetStrength() >= 19.1 and parent:GetAgility() >= 19.1 and parent:GetIntellect() >= 19.1
        if not IsTeamWiped(parent) and self.has_stats and self:GetAbility():IsCooldownReady() and IsRevivePossible(parent) then
            return self.reinc_time
        else
            return 0
        end
    end

    function modifier_jeanne_la_pucelle:OnDeath(args)
        local parent = self:GetParent()
        if args.unit == parent and args.reincarnate and self.has_stats and self:GetAbility():IsCooldownReady() then
            local ability = self:GetAbility()
            ability:StartCooldown(ability:GetCooldown(-1))
            parent:EmitSound("Ruler.LaPucelle.Loop")
            parent:EmitSound("ruler_attack_02")
            AddFOWViewer(parent:GetTeamNumber(), parent:GetAbsOrigin(), 1200, self.reinc_time, false)
            CreateModifierThinker(parent, ability, "modifier_jeanne_la_pucelle_phase1_aura", {duration=self.reinc_time}, parent:GetAbsOrigin(), parent:GetTeamNumber(), false)
            local masterCombo = parent.MasterUnit2:FindAbilityByName(ability:GetAbilityName())
            if masterCombo then
                masterCombo:EndCooldown()
                masterCombo:StartCooldown(ability:GetCooldown(-1))
            end 
            parent.oncombo = true
        end
    end
end

---@class modifier_jeanne_la_pucelle_phase1_aura : CDOTA_Modifier_Lua
modifier_jeanne_la_pucelle_phase1_aura = class({})
modifier_jeanne_la_pucelle_phase1_aura.IsHidden = function(self) return true end

if IsServer() then
    function modifier_jeanne_la_pucelle_phase1_aura:OnCreated(args)
        local caster = self:GetCaster()
        local ability = self:GetAbility()
        local location = self:GetParent():GetAbsOrigin() + Vector(0, 0, 100)
        self.pcf = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_egg.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
        ParticleManager:SetParticleControl(self.pcf, 0, location)
        ParticleManager:SetParticleControl(self.pcf, 1, location)
        ParticleManager:SetParticleControl(self.pcf, 2, location) 
        --caster:AddNewModifier(caster,ability,"modifier_jeanne_la_pucelle_phase1_pause",{duration =ability:GetSpecialValueFor("phase1_duration")})
    end

    function modifier_jeanne_la_pucelle_phase1_aura:OnDestroy(args)
        local caster = self:GetCaster()
        local ability = self:GetAbility()
        local radius = ability:GetSpecialValueFor("phase1_radius")
        caster:StopSound("Ruler.LaPucelle.Loop")
        caster:EmitSound("Ruler.LaPucelle.End")
        local pcf_explode = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf", PATTACH_ABSORIGIN, caster)
        ParticleManager:SetParticleControl(pcf_explode, 1, Vector(radius,radius,radius))
        ParticleManager:ReleaseParticleIndex(pcf_explode)
        ParticleManager:DestroyParticle(self.pcf, false)
        ParticleManager:ReleaseParticleIndex(self.pcf)
        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
        for _, v in pairs(targets) do
            DoDamage(caster, v, v:GetMaxHealth() * (ability:GetSpecialValueFor("phase1_dmg_pct")/100), DAMAGE_TYPE_PURE, 0, ability, false)
        end
        caster:AddNewModifier(caster, ability, "modifier_jeanne_la_pucelle_phase2", {duration = ability:GetSpecialValueFor("phase2_duration")})
        caster.oncombo = false
        UTIL_Remove(self:GetParent())    
    end


    function modifier_jeanne_la_pucelle_phase1_aura:IsAura()
        return true
    end

    function modifier_jeanne_la_pucelle_phase1_aura:GetModifierAura()
        return "modifier_jeanne_la_pucelle_phase1_debuff"
    end

    function modifier_jeanne_la_pucelle_phase1_aura:GetAuraRadius()
        return self:GetAbility():GetSpecialValueFor("phase1_radius")
    end

    function modifier_jeanne_la_pucelle_phase1_aura:GetAuraSearchTeam()
        return DOTA_UNIT_TARGET_TEAM_ENEMY
    end

    function modifier_jeanne_la_pucelle_phase1_aura:GetAuraSearchFlags()
        return DOTA_UNIT_TARGET_FLAG_NONE
    end

    function modifier_jeanne_la_pucelle_phase1_aura:GetAuraSearchType()
        return DOTA_UNIT_TARGET_ALL
    end

end


---@class modifier_jeanne_la_pucelle_phase1_pause : CDOTA_Modifier_Lua
modifier_jeanne_la_pucelle_phase1_pause = class({})

function modifier_jeanne_la_pucelle_phase1_pause:IsDebuff() return true end

function modifier_jeanne_la_pucelle_phase1_pause:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = false,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_DISARMED] = true,
        [MODIFIER_STATE_ROOTED] = true
    }
end




---@class modifier_jeanne_la_pucelle_phase1_debuff : CDOTA_Modifier_Lua
modifier_jeanne_la_pucelle_phase1_debuff = class({})

function modifier_jeanne_la_pucelle_phase1_debuff:GetEffectName()
    return "particles/units/heroes/hero_phoenix/phoenix_supernova_radiance.vpcf"
end

if IsServer() then
    function modifier_jeanne_la_pucelle_phase1_debuff:OnCreated(args)
        local ability = self:GetAbility()
        self.tick = 0.25
        self.slow = -(ability:GetSpecialValueFor("phase1_slow"))
        self:StartIntervalThink(self.tick)
    end

    function modifier_jeanne_la_pucelle_phase1_debuff:OnIntervalThink()
        local ability = self:GetAbility()
        local duration = ability:GetSpecialValueFor("phase1_duration")
        if self.tick >= duration then self:StartIntervalThink(-1) end -- slightly hacky, ensure that we don't deal more than appropriate damage.
        local parent = self:GetParent()
        local damage = parent:GetMaxHealth() * ((ability:GetSpecialValueFor("phase1_dmg_pct")/100) / duration) * self.tick
        DoDamage(self:GetCaster(), parent, damage, DAMAGE_TYPE_MAGICAL, 0, self:GetAbility(), false)
    end

    function modifier_jeanne_la_pucelle_phase1_debuff:DeclareFunctions()
        return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
    end

    function modifier_jeanne_la_pucelle_phase1_debuff:GetModifierMoveSpeedBonus_Percentage()
        return self.slow
    end
end

---@class modifier_jeanne_la_pucelle_phase2 : CDOTA_Modifier_Lua
modifier_jeanne_la_pucelle_phase2 = class({})
modifier_jeanne_la_pucelle_phase2.IsHidden = function(self) return true end

function modifier_jeanne_la_pucelle_phase2:GetEffectName()
    return "particles/econ/events/ti6/radiance_owner_ti6.vpcf"
end

function modifier_jeanne_la_pucelle_phase2:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_SILENCED] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true
    }
end

if IsServer() then
    function modifier_jeanne_la_pucelle_phase2:OnCreated(args)
        self:StartIntervalThink(0.25)
    end

    function modifier_jeanne_la_pucelle_phase2:OnIntervalThink()
        local parent = self:GetParent()
        CreateModifierThinker(parent, self:GetAbility(), "modifier_jeanne_la_pucelle_fire_thinker", {duration = 2.1}, parent:GetAbsOrigin(), parent:GetTeamNumber(), false)
    end

    function modifier_jeanne_la_pucelle_phase2:OnDestroy()
        local parent = self:GetParent()
        parent:StopSound("Hero_DoomBringer.ScorchedEarthAura")
        parent:StopSound("ruler_la_pucelle_loop")
        ResetAbilities(parent)
        ResetItems(parent)
        parent:SetHealth(parent:GetMaxHealth())
        parent:GiveMana(parent:GetMaxMana())
    end
end

---@class modifier_jeanne_la_pucelle_fire_thinker : CDOTA_Modifier_Lua
modifier_jeanne_la_pucelle_fire_thinker = class({})

if IsServer() then
    function modifier_jeanne_la_pucelle_fire_thinker:OnCreated(args)
        self.particle = ParticleManager:CreateParticle("particles/custom/ruler/la_pucelle/la_pucelle_flame.vpcf", PATTACH_CUSTOMORIGIN, nil)
        ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
        ParticleManager:SetParticleControl(self.particle, 1, Vector(self:GetDuration(),0,0))
        self:StartIntervalThink(1)
    end

    function modifier_jeanne_la_pucelle_fire_thinker:OnIntervalThink()
        local parent = self:GetParent()
        local ability = self:GetAbility()
        local targets = FindUnitsInRadius(parent:GetTeam(), parent:GetAbsOrigin(), nil, 325, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
        for k, v in pairs(targets) do
            if not v:HasModifier("modifier_jeanne_la_pucelle_fire_damage") then
                v:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_jeanne_la_pucelle_fire_damage", {duration = 1})
            end
        end
    end

    function modifier_jeanne_la_pucelle_fire_thinker:OnDestroy()
        ParticleManager:DestroyParticle(self.particle, false)
        ParticleManager:ReleaseParticleIndex(self.particle)
        UTIL_Remove(self:GetParent())
    end
end

---@class modifier_jeanne_la_pucelle_fire_damage : CDOTA_Modifier_Lua
modifier_jeanne_la_pucelle_fire_damage = class({})
modifier_jeanne_la_pucelle_fire_damage.IsHidden = function(self) return true end

if IsServer() then
    function modifier_jeanne_la_pucelle_fire_damage:OnCreated(args)
        local ability = self:GetAbility()
        local parent = self:GetParent()
        DoDamage(self:GetCaster(), parent, parent:GetHealth() * (ability:GetSpecialValueFor("phase2_fire_dps")/100), DAMAGE_TYPE_MAGICAL, 0, ability, false)
    end
end