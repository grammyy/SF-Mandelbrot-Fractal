--@name SF Fractal
--@author Elias

if SERVER then
    local src=chip():isWeldedTo()
    
    if src then
        src:linkComponent(chip())
    end
else
    local scale=1
    local data={
        xCartMin=-2.1/scale,
        xCartMax=0.8/scale,
        yCartMin=-1.2/scale,
        yCartMax=1.2/scale,
        maxEscape=math.clamp(math.floor(244/7)*7,14,1792),
        loaded=false
    }
    local thread
    version=1.6
    repo="https://raw.githubusercontent.com/grammyy/SF-Mandelbrot-Fractal/main/version"
    
    http.get("https://raw.githubusercontent.com/grammyy/SF-linker/main/linker.lua",function(data)
        loadstring(data)()
        
        load({
            "https://raw.githubusercontent.com/grammyy/SF-linker/main/public%20libs/version%20changelog.lua"
        })
    end)
    
    render.createRenderTarget("fractal")
    
    function pixelToCartY(y)
        return data.yCartMin+((data.yCartMax-data.yCartMin)*(y/512))
    end
    
    function pixelToCartX(x)
        return data.xCartMin+((data.xCartMax-data.xCartMin)*(x/(1024/data.src.RatioX)))
    end

    function calcuEscape(xCart,yCart)
        local time=0
        local x1=xCart*scale
        local y1=yCart*scale
        local x2
        local y2
        
        while math.sqrt(x1*x1+y1*y1)<2 and time<data.maxEscape do
            x2=(x1*x1)-(y1*y1)+xCart*scale
            y2=(2*x1*y1)+yCart*scale
            x1=x2
            y1=y2
            time=time+1
        end
        
        return time
    end
    
    function rgbNum(time)
        if time<=2 then
            return {0,0,0}
        elseif time==data.maxEscape then
            return {0,25,0}
        end
        
        local r
        local g
        local b
        
        local increments=math.floor(data.maxEscape/7)
        local case=math.floor(time/increments)
        local remain=time%increments
        
        if case==0 then
            r=0
            g=math.floor(256/increments)*remain
            b=0
        end
        
        if case==1 then
            r=0
            g=255
            b=math.floor(256/increments)*remain
        end
        
        if case==2 then
            r=math.floor(256/increments)*remain
            g=255
            b=255
        end
        
        if case==3 then
            r=math.floor(256/increments)*remain
            g=0
            b=255
        end
        
        if case==4 then
            r=255
            g=math.floor(256/increments)*remain
            b=255
        end
        
        if case==5 then
            r=255
            g=math.floor(256/increments)*remain
            b=0
        end
        
        if case==6 then
            r=255
            g=255
            b=math.floor(256/increments)*remain
        end
        
        return {r,g,b}
    end
    
    hook.add("render","",function()
        x,y=render.cursorPos()
        
        if !data.src then
            data.src=render.getScreenInfo(render.getScreenEntity())
        end
        
        render.setRenderTargetTexture("fractal")
        render.drawTexturedRect(0,0,1024,1024)
        
        if !data.loaded then
            render.selectRenderTarget("fractal")
            
            local now = timer.systime()
            
            if !thread then
                thread=coroutine.create(function()
                    for y=0,512/scale do
                        local yCart=pixelToCartY(y*scale)
                            
                        for x=0,(1024/data.src.RatioX)/scale do
                            local xCart=pixelToCartX(x*scale/data.src.RatioX)
                            local escape=calcuEscape(xCart,yCart)
                                
                            local rgb=rgbNum(escape)
                                
                            local index=(y*512/scale+x)*4
            
                            render.setColor(Color(rgb[1],rgb[2],rgb[3]))
                            render.drawRectFast(x*scale,y*scale,scale,scale)
                            
                            if quotaAverage()>0.006*0.9 then
                                coroutine.yield()
                            end
                        end
                    end
                end)
            end

            if coroutine.status(thread)=="suspended" and quotaAverage()<0.9*0.95 then
                coroutine.resume(thread)
            end
            
            if coroutine.status(thread)=="dead" then
                data.loaded=true
                thread=nil
            end
        end
    end)
        
    hook.add("inputPressed","",function(key)
        if x and data.src and key==15 then
            local w=math.floor((1024)*((!player():keyDown(79) and 0.2 or 1)/2))
            local h=math.floor(512*((!player():keyDown(79) and 0.2 or 1)/2))

            data.xCartMin=pixelToCartX((x/data.src.RatioX)-w)
            data.xCartMax=pixelToCartX((x/data.src.RatioX)+w)
            data.yCartMin=pixelToCartY((y)-h)
            data.yCartMax=pixelToCartY((y)+h)
            
            data.loaded=false
            thread=nil
        end
    end)
end