local cloneref = cloneref or function(i: Instance) return i; end;
local clonefunction = clonefunction or function(f: (...any) -> (...any)) return f; end;
local newcclosure = newcclosure or clonefunction;
local executor = (identifyexecutor and select(2, pcall(identifyexecutor))) and identifyexecutor() or "Your executor";

if not (hookfunction and require) then
    return error(executor .. " is missing " .. (not hookfunction and "hookfunction " or "") .. (not require and "require" or ""));
end;

local RS: ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"));
local Players = game:GetService("Players");

local plr = Players.LocalPlayer;
local cam = workspace.CurrentCamera;

local mouse = plr:GetMouse();

local s, GunHandler = pcall(require, RS.Modules.GunHandler);
if not s then
    return warn(executor .. " returned an error while trying to require RS.Modules.GunHandler:\n" .. GunHandler);
end;

local Chars: Folder = workspace:FindFirstChild("Players");
if not Chars then
    return warn("Script needs updating");
end;

local isVisible = function(part: BasePart): (boolean, Instance?)
    local char = plr.Character;
    if not char then return false, nil; end;

    local rp = RaycastParams.new();
    rp.FilterType = Enum.RaycastFilterType.Exclude;
    rp.FilterDescendantsInstances = {char};
    rp.IgnoreWater = true;

    local origin = cam.CFrame.Position;

    local dir = part.Position - origin;
    local result: RaycastResult = workspace:Raycast(origin, dir, rp);
    if not result then return true, nil; end;

    if result.Instance:IsDescendantOf(part.Parent) then
        return true, result.Instance;
    end;

    return false, result.Instance;
end;

local getTarget = function()
    local cPart, cDistance = nil, math.huge;

    for _, char: Model in next, Chars:GetChildren() do
        if char == plr.Character or (char:FindFirstChild("BodyEffects") and char.BodyEffects["K.O"].Value) or char:FindFirstChildOfClass("ForceField") then continue; end;

        local tPart: BasePart = char:FindFirstChild("Head") or char.PrimaryPart or char:FindFirstChild("HumanoidRootPart");
        if not tPart then continue; end;

        local pos, onScreen = cam:WorldToViewportPoint(tPart.Position);
        if not onScreen then continue; end;

        local v, nTPart = isVisible(tPart);
        if not v then continue; end;

        if nTPart then tPart = nTPart; end;

        local distance = (Vector2.new(pos.X, pos.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude;
        if distance < cDistance then
            cPart = tPart;
            cDistance = distance;
        end;
    end;

    return cPart;
end;

local old; old = clonefunction(hookfunction(GunHandler.shoot, newcclosure(function(args)
    if args["Shooter"] == plr.Character then
        local _args = args;
        local c = getTarget();
        if c then
            _args["AimPosition"] = c.Position;
            if _args["Hit"] then
                _args["Hit"] = c;
            end;
            return old(_args);
        end;
    end;

    return old(args);
end)));
