# light-class

A lightweight, single-file object-oriented programming (OOP) library for Lua.

## Features

- **Lightweight**: Single file, no dependencies.
- **Simple Syntax**: Intuitive API for defining classes and inheritance.
- **Inheritance**: Supports single inheritance with `class.extend`.
- **Metamethods**: Automatically inherits metamethods (like `__add`, `__tostring`, etc.) from superclasses.
- **Compatibility**: Designed to work with Lua 5.1+, LuaJIT, and Lua 5.4 (handles `__name` and `__tostring` formatting automatically).

## Installation

Simply copy the `light-class.lua` file into your project directory.

## Usage

### 1. Creating a Class

```lua
local class = require("light-class")

-- Define a new class
local Dog = class.new("Dog")

-- Constructor
function Dog:__init(name)
    self.name = name
end

-- Method
function Dog:bark()
    print(self.name .. " says Woof!")
end

-- Instantiation
local myDog = Dog("Rex")
myDog:bark() -- Output: Rex says Woof!
```

### 2. Inheritance

You can extend existing classes using `class.extend`.

```lua
local Animal = class.new("Animal")

function Animal:__init(name)
    self.name = name
end

function Animal:speak()
    print("...")
end

-- Create a derived class
local Cat = class.extend("Cat", Animal)

function Cat:__init(name, color)
    -- Call super constructor
    Animal.__init(self, name)
    self.color = color
end

function Cat:speak()
    print(self.name .. " (color: " .. self.color .. ") meows.")
end

local myCat = Cat("Whiskers", "Black")
myCat:speak() -- Output: Whiskers (color: Black) meows.
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
