-- EXE.HUB | games/bizarre_lineage.lua  v1.1.0
local BL={}
BL.Name    = "Bizarre Lineage"
BL.Version = "v1.1.0"

local TP_LOCS={"Spawn","Bus Stop","Mob Area","Boss Room","Safe Zone"}
local MOB_LIST={"All Mobs","[Mobs TBA]"}

BL.Tabs={
    {name="Main",buildFn=function(ctx)
        local o,D,pal=ctx.objs,ctx.Draw,ctx.C
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local h2=math.floor((cw-6)/2)
        local sy=cy

        local afC=ctx.card(cx,sy,h2,"AUTO FARM")
        local stC=ctx.card(cx+h2+6,sy,h2,"STATUS")
        local ay=afC.cy
        ay=ctx.dropdown(afC.cx,ay,afC.cw,"bl_mob",MOB_LIST,"All Mobs")
        ay=ctx.toggle(afC.cx,ay,afC.cw,"blFarm","Auto Farm Mob")
        afC.finalize(ay)

        local sty=stC.cy
        o[#o+1]=D.Text(stC.cx,sty,"Game :",pal.muted,10,6)
        o[#o+1]=D.Text(stC.cx+44,sty,"Bizarre Lineage",pal.white,11,6)
        sty=sty+16
        o[#o+1]=D.Text(stC.cx,sty,"Module :",pal.muted,10,6)
        o[#o+1]=D.Text(stC.cx+50,sty,BL.Version,pal.white,11,6)
        sty=sty+4
        stC.finalize(sty+8)
    end},

    {name="Items",buildFn=function(ctx)
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local h2=math.floor((cw-6)/2)
        local sy=cy
        local c1=ctx.card(cx,sy,h2,"AUTO COLLECT")
        local c2=ctx.card(cx+h2+6,sy,h2,"AUTO SELL")
        local y1=ctx.toggle(c1.cx,c1.cy,c1.cw,"blCollect","Auto Collect")
        c1.finalize(y1)
        local y2=ctx.toggle(c2.cx,c2.cy,c2.cw,"blSell","Auto Sell")
        c2.finalize(y2)
        sy=math.max(y1,y2)+10
        local c3=ctx.card(cx,sy,h2,"EQUIP ITEM")
        local c4=ctx.card(cx+h2+6,sy,h2,"USE ITEM")
        local y3=ctx.toggle(c3.cx,c3.cy,c3.cw,"blEquip","Auto Equip")
        c3.finalize(y3)
        local y4=ctx.toggle(c4.cx,c4.cy,c4.cw,"blUse","Auto Use")
        c4.finalize(y4)
    end},

    {name="Teleport",buildFn=function(ctx)
        local o,D,pal=ctx.objs,ctx.Draw,ctx.C
        local cx,cy,cw=ctx.cx,ctx.cy,ctx.cw
        local h2=math.floor((cw-6)/2)
        local sy=cy

        local bsC=ctx.card(cx,sy,h2,"BUS STOP")
        local msC=ctx.card(cx+h2+6,sy,h2,"MOB SPAWN")
        local by=bsC.cy
        by=ctx.dropdown(bsC.cx,by,bsC.cw,"bl_tp_bs",TP_LOCS,"Choose location")
        by=ctx.button(bsC.cx,by,bsC.cw,"Teleport",function()
            print("[BL TP] BusStop")
        end)
        bsC.finalize(by)
        local my2=msC.cy
        my2=ctx.dropdown(msC.cx,my2,msC.cw,"bl_tp_ms",TP_LOCS,"Choose location")
        my2=ctx.button(msC.cx,my2,msC.cw,"Teleport",function()
            print("[BL TP] MobSpawn")
        end)
        msC.finalize(my2)
        sy=math.max(by,my2)+10

        local npC=ctx.card(cx,sy,cw,"NPC")
        local ny=npC.cy
        ny=ctx.dropdown(npC.cx,ny,npC.cw,"bl_tp_npc",{"Main NPC","Raid NPC"},"Choose")
        ny=ctx.button(npC.cx,ny,npC.cw,"Teleport to NPC",function()
            print("[BL TP] NPC")
        end)
        npC.finalize(ny)
    end},
}

function BL.Init(deps)
    deps.log("Bizarre Lineage "..BL.Version.." loaded.")
    deps.UI.Notify("Bizarre Lineage","Module "..BL.Version.." loaded","success")
end

if _G.__EXE_HUB_MODULES then _G.__EXE_HUB_MODULES["bizarre_lineage"]=BL end
return BL