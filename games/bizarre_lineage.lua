-- EXE.HUB | games/bizarre_lineage.lua  v1.0.2
local BL = {}
BL.Name    = "Bizarre Lineage"
BL.Version = "v1.0.2"

BL.Tabs = {
    {name="Main", buildFn=function(ctx)
        local o,D,col=ctx.objs,ctx.Draw,ctx.C
        local sy=ctx.cy
        local af=ctx.card(ctx.cx,sy,ctx.cw,"AUTO FARM")
        local ay=af.cy
        ay=ctx.toggle(af.cx,ay,af.cw,"blAutoFarm","Auto Farm")
        af.finalize(ay)
        sy=ay+10
        local st=ctx.card(ctx.cx,sy,ctx.cw,"STATUS")
        local sty=st.cy
        o[#o+1]=D.Text(st.cx,sty,"Game :",col.muted,9,6)
        o[#o+1]=D.Text(st.cx+40,sty,"Bizarre Lineage",col.white,10,6)
        sty=sty+14
        o[#o+1]=D.Text(st.cx,sty,"Module :",col.muted,9,6)
        o[#o+1]=D.Text(st.cx+46,sty,BL.Version,col.white,10,6)
        sty=sty+4
        st.finalize(sty+8)
    end},

    {name="Items", buildFn=function(ctx)
        local o,D,col=ctx.objs,ctx.Draw,ctx.C
        local sy=ctx.cy
        local half=math.floor((ctx.cw-6)/2)
        local c1=ctx.card(ctx.cx,sy,half,"AUTO COLLECT")
        local c2=ctx.card(ctx.cx+half+6,sy,half,"AUTO SELL")
        local y1=ctx.toggle(c1.cx,c1.cy,c1.cw,"blAutoCollect","Auto Collect")
        c1.finalize(y1)
        local y2=ctx.toggle(c2.cx,c2.cy,c2.cw,"blAutoSell","Auto Sell")
        c2.finalize(y2)
    end},

    {name="Teleport", buildFn=function(ctx)
        local o,D,col=ctx.objs,ctx.Draw,ctx.C
        local sy=ctx.cy
        local half=math.floor((ctx.cw-6)/2)
        local bs=ctx.card(ctx.cx,sy,half,"BUS STOP")
        local ms=ctx.card(ctx.cx+half+6,sy,half,"MOB SPAWN")
        local yb=ctx.button(bs.cx,bs.cy,bs.cw,"Teleport",function() print("[BL TP] BusStop") end)
        bs.finalize(yb)
        local ym=ctx.button(ms.cx,ms.cy,ms.cw,"Teleport",function() print("[BL TP] MobSpawn") end)
        ms.finalize(ym)
        sy=math.max(yb,ym)+10
        local np=ctx.card(ctx.cx,sy,ctx.cw,"NPC")
        local ny=np.cy
        ny=ctx.button(np.cx,ny,np.cw,"NPC — Main",function() print("[BL TP] NPC") end)
        o[#o+1]=D.Text(np.cx,ny,"  ╰ Raid NPC",col.muted,9,6)
        ny=ny+12
        ny=ctx.button(np.cx,ny,np.cw,"Raid NPC",function() print("[BL TP] RaidNPC") end)
        np.finalize(ny)
    end},
}

function BL.Init(deps)
    deps.log("Bizarre Lineage "..BL.Version.." loaded.")
    deps.UI.Notify("Bizarre Lineage","Module "..BL.Version.." loaded","success")
end

if _G.__EXE_HUB_MODULES then _G.__EXE_HUB_MODULES["bizarre_lineage"]=BL end
return BL