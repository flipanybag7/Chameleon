#import "CHIdentityEngine.h"
#import <WebKit/WebKit.h>

static NSString *CHCanvasProtectJS(void);

%hook WKWebView

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    WKWebView *webView = %orig;

    if ([CHIdentityEngine isHookEnabled:@"SpoofCanvas"]) {
        NSString *js = CHCanvasProtectJS();
        if (js) {
            WKUserScript *script = [[WKUserScript alloc] initWithSource:js
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                       forMainFrameOnly:NO];
            [webView.configuration.userContentController addUserScript:script];
        }
    }

    return webView;
}

%end

%hook WKUserContentController

- (void)addUserScript:(WKUserScript *)userScript {
    %orig;

    if ([CHIdentityEngine isHookEnabled:@"SpoofCanvas"]) {
        static dispatch_once_t once;
        static NSString *protectJS = nil;
        dispatch_once(&once, ^{
            protectJS = CHCanvasProtectJS();
        });

        if (protectJS) {
            WKUserScript *chameleonScript = [[WKUserScript alloc] initWithSource:protectJS
                                                                   injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                                forMainFrameOnly:NO];
            %orig(chameleonScript);
        }
    }
}

%end

static NSString *CHCanvasProtectJS(void) {
    NSString *diskPath = @"/Library/Application Support/Chameleon/canvas_protect.js";
    NSString *js = [NSString stringWithContentsOfFile:diskPath encoding:NSUTF8StringEncoding error:nil];
    if (js) return js;

    return @"(function(){"
    "var _origGetContext=HTMLCanvasElement.prototype.getContext;"
    "var _origToDataURL=HTMLCanvasElement.prototype.toDataURL;"
    "var _origToBlob=HTMLCanvasElement.prototype.toBlob;"
    "HTMLCanvasElement.prototype.getContext=function(){"
    "var ctx=_origGetContext.apply(this,arguments);"
    "if(!ctx||arguments[0]!=='2d')return ctx;"
    "var _origGetImageData=ctx.getImageData;"
    "ctx.getImageData=function(){"
    "var imgData=_origGetImageData.apply(this,arguments);"
    "if(!imgData)return imgData;"
    "var d=imgData.data;"
    "for(var i=0;i<d.length;i+=4){"
    "d[i]=Math.max(0,Math.min(255,d[i]+(Math.random()<0.25?1:-1)));"
    "d[i+1]=Math.max(0,Math.min(255,d[i+1]+(Math.random()<0.25?1:-1)));"
    "d[i+2]=Math.max(0,Math.min(255,d[i+2]+(Math.random()<0.25?1:-1)));"
    "}"
    "return imgData;};"
    "return ctx;};"
    "HTMLCanvasElement.prototype.toDataURL=function(){"
    "var ctx=_origGetContext.apply(this,['2d']);"
    "if(ctx){ctx.fillStyle='rgba('+(Math.random()*0.5|0)+','+(Math.random()*0.5|0)+','+(Math.random()*0.5|0)+',0.0001)';ctx.fillRect(0,0,1,1);}"
    "return _origToDataURL.apply(this,arguments);};"
    "HTMLCanvasElement.prototype.toBlob=function(){"
    "var cb=arguments[0];if(typeof cb!=='function')return _origToBlob.apply(this,arguments);"
    "arguments[0]=function(b){"
    "var ctx=_origGetContext.apply(this,['2d']);"
    "if(ctx&&b){ctx.fillStyle='rgba('+(Math.random()*0.5|0)+','+(Math.random()*0.5|0)+','+(Math.random()*0.5|0)+',0.0001)';ctx.fillRect(0,0,1,1);}"
    "cb(b);};"
    "return _origToBlob.apply(this,arguments);};"
    "if(typeof WebGLRenderingContext!=='undefined'){"
    "var _glGetParam=WebGLRenderingContext.prototype.getParameter;"
    "var _glGetExt=WebGLRenderingContext.prototype.getExtension;"
    "var _glGetSupportedExts=WebGLRenderingContext.prototype.getSupportedExtensions;"
    "WebGLRenderingContext.prototype.getParameter=function(p){"
    "if(p===0x1F01||p===0x9245)return'Apple GPU (spoofed)';"
    "if(p===0x1F00||p===0x9246)return'Apple Inc.';"
    "if(p===0x1F02)return'WebGL 1.0 (OpenGL ES 3.0)';"
    "return _glGetParam.apply(this,arguments);};"
    "WebGLRenderingContext.prototype.getExtension=function(name){"
    "if(name==='WEBGL_debug_renderer_info')return null;"
    "return _glGetExt.apply(this,arguments);};"
    "WebGLRenderingContext.prototype.getSupportedExtensions=function(){"
    "var exts=_glGetSupportedExts.apply(this,arguments)||[];"
    "return exts.filter(function(e){return e!=='WEBGL_debug_renderer_info';});};}"
    "if(typeof WebGL2RenderingContext!=='undefined'){"
    "var _gl2GetParam=WebGL2RenderingContext.prototype.getParameter;"
    "WebGL2RenderingContext.prototype.getParameter=function(p){"
    "if(p===0x1F01||p===0x9245)return'Apple GPU (spoofed)';"
    "if(p===0x1F00||p===0x9246)return'Apple Inc.';"
    "if(p===0x1F02)return'WebGL 2.0 (OpenGL ES 3.1)';"
    "return _gl2GetParam.apply(this,arguments);};"
    "var _gl2GetExt=WebGL2RenderingContext.prototype.getExtension;"
    "WebGL2RenderingContext.prototype.getExtension=function(name){"
    "if(name==='WEBGL_debug_renderer_info')return null;"
    "return _gl2GetExt.apply(this,arguments);};}"
    "})();";
}
