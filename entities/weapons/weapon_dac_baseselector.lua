AddCSLuaFile()

SWEP.Category = "DAC"
SWEP.Base = "weapon_base"
SWEP.PrintName = "Base Locator"
SWEP.Author = "Tricycle Raptor"
SWEP.Instructions = "Left click to set the origin of your base"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Weight	= 5
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false

SWEP.Slot = 1
SWEP.SlotPos = 2
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"
SWEP.UseHands = false
SWEP.HoldType = "revolver"

local user = nil
local userTeam = nil

local spawnPos = nil
local flagPos = nil
local spawnEnt = NULL
local flagEnt = NULL
local validSpace = false
local wireColor = Color(255,255,255,255)

local otherTeamPos = Vector(0,0,0)
local maxDistance = GetConVar("dac_zone_scale"):GetFloat() * 2000

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

function SWEP:Think()

    user = self:GetOwner()
    userTeam = self:GetOwner():Team()
    
    if SERVER then -- Changed from client to server so other teammates can see the base placement

        local Trace = self.Owner:GetEyeTrace()
        local Dist = (Trace.HitPos - self.Owner:GetPos()):Length()
    
        if Dist <= 350 then -- Maximum base place range, to prevent weirdness
    
            if spawnEnt == NULL and flagEnt == NULL then

                spawnEnt = ents.Create("prop_physics")
                spawnEnt:SetModel("models/ctf_spawnarea/ctf_spawnarea.mdl")
                spawnEnt:Spawn()
                spawnEnt:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE) -- Don't collide with anything, bitch
                spawnEnt:DrawShadow(false)
                spawnEnt:SetMaterial("models/wireframe")

                flagEnt = ents.Create("prop_physics")
                flagEnt:SetModel("models/ctf_flagbase/ctf_flagbase.mdl")
                flagEnt:Spawn()
                flagEnt:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
                flagEnt:DrawShadow(false)
                flagEnt:SetMaterial("models/wireframe")

            else

                spawnPos = Trace.HitPos + Trace.HitNormal * 3
                flagPos = spawnPos + Vector(0,0,100)

                spawnEnt:SetPos(spawnPos)
                flagEnt:SetPos(flagPos)
                spawnEnt:SetColor(wireColor)
                flagEnt:SetColor(wireColor)

                self:TraceCheck(spawnEnt, flagEnt)

                --if (TeamLocations[otherTeam] != nil && (spawnPos - TeamLocations[otherTeam]):Length() < GetConVar("dac_zone_scale"):GetFloat() * 2000) then
                    --wireColor = Color( 255, 0, 0, 255 )
                    --validSpace = false    
                --end

            end
    
        else
    
            if spawnEnt ~= NULL and flagEnt ~= NULL then
                spawnEnt:Remove()
                flagEnt:Remove()
            end

        end

    end

end

function SWEP:PrimaryAttack()

    if SERVER then

        if validSpace == true then

            for teamKey, teamData in pairs(GAMEMODE.Teams) do -- Special thanks to Joseph Tomlinson (@BizzClaw) for some pair programming to figure this out
                if teamKey != userTeam then -- ignore our team
                    local otherTeamPos = teamData.basePos

                    if (otherTeamPos and otherTeamPos != Vector(0,0,0) and spawnPos:Distance(otherTeamPos) < maxDistance) then -- Check the cVar for the build scale
                        self:GetOwner():EmitSound("buttons/button8.wav")
                        return false
                    else
                        net.Start("dac_validspace_sync")
                        net.WriteBool(true)
                        net.Send(user) -- This SHOULD only send to the player who clicks with the tool, but this will have to be tested with another player present
                    end

                end
            end

            GAMEMODE.Teams[userTeam].basePos = spawnPos
            GAMEMODE.Teams[userTeam].baseSet = true

        else
            self:GetOwner():EmitSound("buttons/button8.wav") -- Teammates will hear this, too
            self:GetOwner():ChatPrint("[DAC]: Invalid base location selected.")
        end
        
    end

end

function SWEP:Holster()

    if spawnEnt ~= NULL and flagEnt ~= NULL then
        validSpace = false
        spawnEnt:Remove()
        flagEnt:Remove()
    end
    
    return true

end

function SWEP:TraceCheck(spawnEnt, flagEnt)

    local ent1 = spawnEnt
    local ent2 = flagEnt
	
	local mins1 = ent1:OBBMins()
	local maxs1 = ent1:OBBMaxs()
	local startpos1 = ent1:GetPos()
	local dir1 = ent1:GetUp()
	local len1 = 2

    local mins2 = ent2:OBBMins()
	local maxs2 = ent2:OBBMaxs()
	local startpos2 = ent2:GetPos()
	local dir2 = ent2:GetUp()
	local len2 = 2

	local tr1 = util.TraceHull( {
		start = startpos1,
		endpos = startpos1 + dir1 * len1,
		maxs = maxs1,
		mins = mins1,
		filter = ent1
	} )

    local tr2 = util.TraceHull( {
		start = startpos2,
		endpos = startpos2 + dir2 * len2,
		maxs = maxs2,
		mins = mins2,
		filter = ent2
	} )

	if ( tr1.Hit or tr2.Hit ) then
		wireColor = Color( 255, 0, 0, 255 )
        validSpace = false
    else
        wireColor = Color( 0, 255, 0, 255)
        validSpace = true
    end

    for teamKey, teamData in pairs(GAMEMODE.Teams) do
        if teamKey != userTeam then
            local otherTeamPos = teamData.basePos
            if (otherTeamPos and otherTeamPos != Vector(0,0,0) and spawnPos:Distance(otherTeamPos) < maxDistance) then
                wireColor = Color( 255, 0, 0, 255 )
                validSpace = false
            end
        end
    end

end

function SetupTeamArea()

    BuildArea(user, userTeam, spawnPos, flagPos) -- We should pass in the player, the player's team, and the flag/spawnpos

end

net.Receive("dac_sendbase_confirmation", function(len, ply)

	local confirmationBool = net.ReadBool()
	if confirmationBool == true then
        print("[DAC DEBUG]: Server received confirmation message.")
        SetupTeamArea()
        --PrintTable(GAMEMODE.Teams)
    else
        print("[DAC DEBUG]: Server received rejection message.")
    end

end)