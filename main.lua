#!/usr/bin/env love
-- PHOTON
-- 0.4
-- Editor (love2d)

-- main.lua

-- MIT License
-- Copyright (c) 2019 Alexander Veledzimovich veledz@gmail.com

-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

-- lua<5.3
io.stdout:setvbuf('no')
local unpack = table.unpack or unpack
local utf8 = require('utf8')

local nuklear = require('nuklear')
local fl = require('lib/lovfl')

local set = require('editor/set')
local ui = require('editor/ui')
local PH = require('editor/ph')

-- 0.5
-- add info about systems (buf x,y,count)
-- generate update function for created particle?
-- imporve selection images and forms

-- 0.6
-- ui colors
-- better usability and move place two born
-- show/hide marks
-- import func

local PS = {
        count = 0,
        photons = {},
        imgbase={},
        loadpath={value=''},
        systems={value=1,items={'0'}},
        hotset={value=true},
        codeState=false,
        drag = false,
        x=set.VIEWWID/2,y=set.VIEWHEI/2
    }

function PS.new()
    local photon = PH:new{PS=PS,id=#PS.photons+1}
    PS.photons[#PS.photons+1]=photon
    PS.systems.items[#PS.photons]=tostring(#PS.photons)
    PS.systems.value=#PS.photons
end

function PS.loadImd()
    for k,v in pairs(fl.loadPath(
            PS.loadpath.value,unpack(set.IMGEXT))) do
        PS.imgbase[k]=love.image.newImageData(v)
        if #PS.photons>0 then
            PS.photons[PS.systems.value].set.imgdata.value=k
        end
    end
end

function PS.dropImd(file)
    local path = fl.copyLove(file,set.TMPDIR)
    PS.loadpath.value = set.TMPDIR..'/'..fl.name(path)
    PS.loadImd()
end

function PS.clear()
    for i=#PS.photons, 1,-1 do
        PS.systems={value=1,items={'0'}}
        PS.photons[i].particle:reset()
        PS.photons[i]=nil
    end
end

local nk
function love.load()
    if arg[1] then print(set.VER, set.APPNAME, 'Editor (love2d)', arg[1]) end
    love.window.setMode(set.WID,set.HEI,{vsync=1,resizable=true})
    love.window.setPosition(0,0)
    love.graphics.setBackgroundColor(set.BGCLR)
    love.keyboard.setKeyRepeat(true)
    love.filesystem.createDirectory(set.TMPDIR)
    nk=nuklear.newUI()
end

function love.update(dt)
    local title = string.format('%s %s fps %.2d systems %d particles %d',
                            set.APPNAME, set.VER, love.timer.getFPS(),
                            #PS.photons, PS.count)
    love.window.setTitle(title)

    ui.editor(nk,PS)

    PS.count=0
    if #PS.photons>0 and PS.hotset.value then
        PS.photons[PS.systems.value]:setup()
    end
    for i=1, #PS.photons do
        if not PS.photons[i].particle:isPaused() then
            PS.photons[i].particle:update(dt)
        end
        PS.count=PS.count+PS.photons[i].particle:getCount()
    end
end

function love.draw()
    love.graphics.rectangle('line',
            PS.x-set.MARKRAD,PS.y-set.MARKRAD,
            set.MARKRAD*2,set.MARKRAD*2)

    for i=1, #PS.photons do PS.photons[i]:draw() end
    nk:draw()
end

function love.filedropped(file)
    PS.dropImd(file)
end

function love.keypressed(key, unicode, isrepeat)
    nk:keypressed(key, unicode, isrepeat)
end

function love.keyreleased(key, unicode)
    nk:keyreleased(key, unicode)
end

function love.mousepressed(x, y, button, istouch)
    nk:mousepressed(x, y, button, istouch)
    if button==1 then
        for i=1, #PS.photons do
            local px, py = PS.photons[i].particle:getPosition()
            if ((px-x)^2 + (py-y)^2) < set.MARKRAD^2 and not PS.drag then
                PS.systems.value=i
                PS.drag = true
                break
            end
        end
    end
    if button==2 then
        if PS.codeState=='active' then
            love.system.setClipboardText(
                    PS.photons[PS.systems.value].code.value)
        end
    end
end

function love.mousereleased(x, y, button, istouch)
    nk:mousereleased(x, y, button, istouch)
    if button==1 then
        PS.drag = false
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    nk:mousemoved(x, y, dx, dy, istouch)
    if #PS.photons>0 and PS.drag then
        PS.photons[PS.systems.value].particle:moveTo(x,y)
    end
end

function love.wheelmoved(x, y) nk:wheelmoved(x, y) end

function love.textinput(text) nk:textinput(text) end

function love.quit()
    fl.removeAll(set.TMPDIR,true)
    print(set.VER, set.APPNAME, 'Editor (love2d)', 'quit')
end
