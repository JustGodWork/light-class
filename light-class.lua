---@class LightClassFactory
---@overload table<string, LightClass>
class = {};

local container = {}; ---@type table<string, LightClass>
local base_cls = {}; ---@class LightClassBase
local meta_methods = {
    "__mode",
    "__metatable",
    "__tostring",
    "__gc",
    "__add",
    "__sub",
    "__mul",
    "__div",
    "__mod",
    "__pow",
    "__unm",
    "__idiv",
    "__band",
    "__bor",
    "__bxor",
    "__bnot",
    "__shl",
    "__shr",
    "__concat",
    "__len",
    "__eq",
    "__lt",
    "__le",
    "__index",
    "__newindex",
    "__call",
    "__pairs",
    "__close"
};

---@class lc_metatable: metatable
---@field public __name string The meta name of the class
---@field public __cls boolean Indicates that this is a class metatable
---@field public __clsi boolean Indicates that this is an instance metatable
---@field public __supermt lc_metatable The metatable of the superclass

--- Get Lua version as major and minor numbers
---@return number major, number minor
local function get_lua_version()
    local major, minor = _VERSION:match("Lua (%d+)%.(%d+)");
    return tonumber(major), tonumber(minor);
end

--- Lua < 5.4 compatibility
--- Make __tostring method returns class name and address
---@param obj table
---@param name string
---@return fun(self: table): string | nil
local function make_name_string(obj, name)
    local major, minor = get_lua_version();
    if (major < 5 or (major == 5 and minor < 4)) then
        return function(self)
            return string.format("%s: %p", name, self);
        end
    end

    return nil;
end

---@generic T: LightClass
---@generic U: LightClass
---@param name `T`
---@param super? U
local function new_class(name, super)
    local cls = {};
    local metatable = {};

    super = type(super) == "table" and super or base_cls;

    local super_metatable = getmetatable(super) or {};

    metatable.__name = name;
    metatable.__tostring = make_name_string(cls, name);

    metatable.__index = super;
    metatable.__supermt = super_metatable;
    metatable.__cls = true;
    metatable.__clsi = false;

    for i = 1, #meta_methods do
        local method_name = meta_methods[i];

        if (metatable[method_name] == nil) then
            local super_metamethod = rawget(super_metatable, method_name);
            if (super_metamethod ~= nil) then
                rawset(metatable, method_name, super_metamethod);
            end
        end
    end

    container[name] = cls;

    return setmetatable(cls, metatable);
end

---@generic T: LightClass
---@param cls T
---@param ... any
---@return T
local function new_instance(cls, ...)
    local obj = {};
    local cls_metatable = getmetatable(cls) or {};
    local metatable = {};

    for i = 1, #meta_methods do
        local name = meta_methods[i];
        local method = rawget(cls, name) or rawget(cls_metatable, name);
        if (method ~= nil) then
            rawset(metatable, name, method);
        end
    end

    if (rawget(metatable, "__tostring") == nil) then
        rawset(metatable, "__tostring",
            make_name_string(obj, cls_metatable.__name)
        );
    end

    rawset(metatable, "__call", function()
        error("Cannot call instance directly. Create a new instance from the class.");
    end);

    metatable.__index = cls;
    metatable.__cls = false;
    metatable.__clsi = true;

    setmetatable(obj, metatable);

    local __init = rawget(cls, "__init"); ---@type fun(self: T, ...: any): void

    if (type(__init) == "function") then
        __init(obj, ...);
    end

    return obj;
end

--- Create a new class
---@generic T: LightClass
---@param name `T`
---@return T
function class.new(name)
    assert(type(name) == "string", "Class name must be a string.");
    assert(container[name] == nil, "Class '" .. name .. "' is already defined.");
    return new_class(name);
end

--- Create a new class that extends a superclass
---@generic T: LightClass
---@generic U: LightClass
---@param name `T`
---@param super U
---@return T
function class.extend(name, super)
    assert(type(name) == "string", "Class name must be a string.");
    assert(container[name] == nil, "Class '" .. name .. "' is already defined.");
    return new_class(name, super);
end

--- Get the metatable (prototype) of a class or instance
---@generic T: LightClass
---@param obj T
---@return lc_metatable
function class.prototype(obj)
    return getmetatable(obj);
end

--- Check if the object is a class
---@param obj any
---@return boolean
function class.is_class(obj)
    local mt = getmetatable(obj);
    return mt ~= nil and mt.__cls == true;
end

--- Check if the object is an instance of a class
---@param obj any
---@return boolean
function class.is_instance(obj)
    local mt = getmetatable(obj);
    return mt ~= nil and mt.__clsi == true;
end

--- Check if the object is an instance of the specified class or its subclasses
---@generic T: LightClass
---@generic U: LightClass
---@param obj T
---@param cls U
---@return boolean
function class.is_instance_of(obj, cls)
    if (not class.is_instance(obj) or not class.is_class(cls)) then
        return false;
    end

    local obj_mt = class.prototype(obj);
    local cls_mt = class.prototype(cls);

    while (obj_mt ~= nil) do
        if (obj_mt == cls_mt) then
            return true;
        end
        local index = rawget(obj_mt, "__index");
        obj_mt = (type(index) == "table") and class.prototype(index) or nil;
    end

    return false;
end

--- Get the type of the object: "class", "instance", or the standard Lua type
---@param obj any
---@return type | "class" | "instance"
function class.type(obj)
    local mt = getmetatable(obj);
    if (mt == nil) then
        return type(obj);
    end
    if (mt.__cls == true) then
        return "class";
    elseif (mt.__clsi == true) then
        return "instance";
    else
        return type(obj);
    end
end

--- Get the name of the class or instance
---@param obj any
---@return string | nil
function class.name(obj)
    local mt = class.prototype(obj);
    return type(mt) == "table" and mt.__name or nil;
end

setmetatable(class, {
    __index = function(_, name)
        return container[name];
    end
});

setmetatable(base_cls, {
    __name = "LightClassBase",
    __call = function(cls, ...)
        return new_instance(cls, ...);
    end
});

return class;
