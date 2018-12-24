pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

debug = false

-- a table comtaining all game entities
entities = {}

function ycomparison(a,b)
  if a.position == nil or b.position == nil then return false end
  return a.position.y + a.position.h >
                  b.position.y + b.position.h
end

function sort(list, comparison)
  for i = 2,#list do
    local j = i
    while j > 1 and comparison(list[j-1], list[j]) do
      list[j],list[j-1] = list[j-1],list[j]
      j -= 1
    end
  end
end

function canwalk(x,y)
 return not fget(mget(x/8,y/8),7)
end

function touching(x1,y1,w1,h1,x2,y2,w2,h2)
 return x1+w1 > x2 and
 x1 < x2+w2 and
 y1+h1 > y2 and
 y1 < y2+h2
end

function newbounds(xoff,yoff,w,h)
 local b = {}
 b.xoff = xoff
 b.yoff = yoff
 b.w = w
 b.h = h
 return b
end

-- creates and returns a new control component
function newcontrol(left,right,up,down,input)
 local c = {}
 c.left = left
 c.right = right
 c.up = up
 c.down = down
 c.input = input
 return c
end

-- creates and returns a new intention component
function newintention()
 local i = {}
 i.left = false
 i.right = false
 i.up = false
 i.down = false
 i.moving = false
 return i
end

-- creates and returns a new position
function newposition(x,y,w,h)
 local p = {}
 p.x = x
 p.y = y
 p.w = w
 p.h = h
 return p
end

-- creates and returns a new sprite
function newsprite(sl,i)
 local s = {}
 s.spritelist = sl
 s.index = i
 s.flip = false
 return s
end

function newanimation(d,t)
 local a = {}
 a.timer = 0
 a.delay = d
 a.type = t
 return a
end

-- creates and returns a new entity
function newentity(position,sprite,control,intention,bounds,animation)
 local e = {}
 e.position = position
 e.sprite = sprite
 e.control = control
 e.intention = intention
 e.bounds = bounds
 e.animation = animation
 return e
end

function playerinput(ent)
  ent.intention.left = btn(ent.control.left)
  ent.intention.right = btn(ent.control.right)
  ent.intention.up = btn(ent.control.up)
  ent.intention.down = btn(ent.control.down)
  ent.intention.moving = ent.intention.left or ent.intention.right or
                         ent.intention.up or ent.intention.down
end

function npcinput(ent)
  ent.intention.left = true
end

controlsystem = {}
controlsystem.update = function()
 for ent in all(entities) do
  if ent.control ~= nil and ent.intention ~= nil then
   ent.control.input(ent)
  end
 end
end

physicssystem = {}
physicssystem.update = function()
 for ent in all(entities) do

  local newx = ent.position.x
  local newy = ent.position.y

  if ent.position ~= nil and ent.intention ~= nil then
   if ent.intention.left then newx -= 1 end
   if ent.intention.right then newx += 1 end
   if ent.intention.up then newy -= 1 end
   if ent.intention.down then newy += 1 end
  end

  local canmovex = true
  local canmovey = true

  --
  -- map collision
  --

  -- update x position if allowed to move
  if not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff) or
     not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) or
     not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff) or
     not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) then
   canmovex = false
  end
  -- update y position if allowed to move
  if not canwalk(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff) or
     not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff) or
     not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff+ent.bounds.h-1) or
     not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff+ent.bounds.h-1) then
   canmovey = false
  end

  --
  -- entity collision
  --

  -- check x
  for o in all(entities) do
   if o ~= ent and
      touching(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
          o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
    canmovex = false
   end
  end

  -- check y
  for o in all(entities) do
   if o ~= ent and
    touching(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
       o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
     canmovey = false
   end
  end

  if canmovex then ent.position.x = newx end
  if canmovey then ent.position.y = newy end

 end
end

animationsystem = {}
animationsystem.update = function()
 for ent in all(entities) do
  if ent.sprite and ent.animation then
   if ent.animation.type == 'always' or (ent.intention and ent.animation.type == 'walk' and ent.intention.moving) then
    -- increment the animation timer
    ent.animation.timer += 1
    -- if the timer is higher than the delay
    if ent.animation.timer > ent.animation.delay then
     -- increment then index ans reset the timer
     ent.sprite.index += 1
     if ent.sprite.index > #ent.sprite.spritelist then
      ent.sprite.index = 1
     end
     ent.animation.timer = 0
    end
   else
    ent.sprite.index = 1
   end
  end
 end
end

gs = {}
gs.update = function()
  cls(3)

  sort(entities, ycomparison)

  --centre camera on player
  camera(-64+player.position.x+(player.position.w/2),
         -64+player.position.y+(player.position.h/2))
  map()

  -- draw all entities with sprites and positions
  for ent in all(entities) do

   -- flip sprites?
   if ent.sprite and ent.intention then
    if ent.sprite.flip == false and ent.intention.left then ent.sprite.flip = true end
    if ent.sprite.flip and ent.intention.right then ent.sprite.flip = false end
   end

   if ent.sprite ~= nil and ent.position ~= nil then
    sspr(ent.sprite.spritelist[ent.sprite.index][1],
         ent.sprite.spritelist[ent.sprite.index][2],
         ent.position.w, ent.position.h,
         ent.position.x, ent.position.y,
         ent.position.w, ent.position.h,
         ent.sprite.flip,false)
   end

   -- draw bounding boxes
   if debug then
    rect(ent.position.x+ent.bounds.xoff,
        ent.position.y+ent.bounds.yoff,
        ent.position.x+ent.bounds.xoff+ent.bounds.w-1,
        ent.position.y+ent.bounds.yoff+ent.bounds.h-1,9)
   end
  end

  camera()
  --crosshair sprite
  --spr(16,64-4,64-4)

end

function _init()
  -- create a player entity
  player = newentity(
   -- create a position component
   newposition(10,10,4,8),
   -- create a sprite component
   newsprite({{8,0},{12,0},{16,0},{20,0}},1),
   -- create a control component
   newcontrol(0,1,2,3,playerinput),
   -- create an intention component
   newintention(),
   -- create a new bounding box
   newbounds(0,6,4,2),
   -- create a new animation component
   newanimation(3,'walk')
  )
  add(entities,player)

  -- create a tree entity
  add(entities,
    newentity(
      -- create a position component
      newposition(30,30,16,16),
      -- create a sprite component
      newsprite({{8,8}},1),
      -- create a control component
      nil,
      -- create an intention component
      nil,
      -- create a new bounding box
      newbounds(6,12,4,4),
      -- create a new animation component
      nil
    )
  )

end

function _update()
 --check player input
 controlsystem.update()
 -- move entities
 physicssystem.update()
 -- animate entities
 animationsystem.update()
end

function _draw()
 gs.update()
end


__gfx__
0000000088888888888888880000000000000000000000000000000000000000cccccccccccc00000000cccc0000cccccccc0000000000000000000000000000
000000008fff8fff8fff8fff0000000000000000000000000000000000000000cccccccccc000000000000cc00cccccccccccc00000440000004400000044000
007007008fff8fff8fff8fff0000000000000000000000000000000000000000ccccccccc00000000000000c0cccccccccccccc0004554000045540000455400
0007700081118111811181110000000000000000000000000000000000000000ccccccccc00000000000000c0cccccccccccccc0045445444454454044544544
0007700011111111111111110000000000000000000000000000000000000000cccccccc0000000000000000cccccccccccccccc045445444454454044544544
0070070011f1111f11f11f110000000000000000000000000000000000000000cccccccc0000000000000000cccccccccccccccc004554000045540000455400
0000000011111111111111110000000000000000000000000000000000000000cccccccc0000000000000000cccccccccccccccc000440000004400000044000
0000000002202020020000020000000000000000000000000000000000000000cccccccc0000000000000000cccccccccccccccc000440000004400000000000
000880000000000bb00000000000000000000000000000000000000000000000cccccccc0000000000000000cccccccccccccccc000440000004400000044000
0008800000000bbbbbbb00000000000000000000000000000000000000000000cccccccc0000000000000000cccccccccccccccc000440000004400000044000
0000000000000bbbbbbb00000000000000000000000000000000000000000000cc7ccccc0000000000000000cccccccccccccccc004554000045540000455400
88000088000bbbbbbbbbbb000000000000000000000000000000000000000000c7c7cccc0000000000000000cccccccccccccccc045445444454454004544540
88000088000bbbbbbbbbbbb00000000000000000000000000000000000000000ccccccccc00000000000000c0cccccccccccccc0045445444454454004544540
0000000000bbbbbbbbbbbbb00000000000000000000000000000000000000000cccccc7cc00000000000000c0cccccccccccccc0004554000045540000455400
0008800000bbbbbbbbbbbbb00000000000000000000000000000000000000000ccccc7c7cc000000000000cc00cccccccccccc00000440000004400000044000
00088000000bbbbbbbbbb0000000000000000000000000000000000000000000cccccccccccc00000000cccc0000cccccccc0000000000000000000000044000
0000000000000bb40bb4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000080800000800000808080808000000000000000008000008080808080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f00000000000000000000000000000000000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f000000000000000000000b080c000000000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f00000000000000000000080808000000000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f00000000000000000000081808190000000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f00000000000000000000081808080c00000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f000000000000000000001b0808081c00000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f00000000000000000000000000000000000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f00000000000000000000000000000000000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f00000000000000000000000000000000000000001f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
