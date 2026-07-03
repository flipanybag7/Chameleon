(function() {
    'use strict';

    // --- Canvas 2D fingerprinting protection ---
    const _origGetContext = HTMLCanvasElement.prototype.getContext;
    HTMLCanvasElement.prototype.getContext = function() {
        const ctx = _origGetContext.apply(this, arguments);
        if (!ctx || arguments[0] !== '2d') return ctx;

        const _origGetImageData = ctx.getImageData;
        ctx.getImageData = function() {
            const imgData = _origGetImageData.apply(this, arguments);
            if (!imgData) return imgData;
            const d = imgData.data;
            for (let i = 0; i < d.length; i += 4) {
                d[i]     = Math.max(0, Math.min(255, d[i]     + (Math.random() < 0.3 ? -1 : 1)));
                d[i + 1] = Math.max(0, Math.min(255, d[i + 1] + (Math.random() < 0.3 ? -1 : 1)));
                d[i + 2] = Math.max(0, Math.min(255, d[i + 2] + (Math.random() < 0.3 ? -1 : 1)));
            }
            return imgData;
        };

        return ctx;
    };

    // --- Canvas toDataURL / toBlob protection ---
    const _origToDataURL = HTMLCanvasElement.prototype.toDataURL;
    HTMLCanvasElement.prototype.toDataURL = function() {
        const ctx = _origGetContext.apply(this, ['2d']);
        if (ctx) {
            ctx.fillStyle = 'rgba(' + (Math.random() * 0.5 | 0) + ',' +
                            (Math.random() * 0.5 | 0) + ',' +
                            (Math.random() * 0.5 | 0) + ',0.0001)';
            ctx.fillRect(0, 0, 1, 1);
        }
        return _origToDataURL.apply(this, arguments);
    };

    // --- WebGL audio fingerprinting: randomize buffer data ---
    if (typeof AudioContext !== 'undefined') {
        const _origCreateBuffer = AudioContext.prototype.createBuffer;
        AudioContext.prototype.createBuffer = function() {
            const buf = _origCreateBuffer.apply(this, arguments);
            const _origGetChannelData = buf.getChannelData;
            buf.getChannelData = function() {
                const data = _origGetChannelData.apply(this, arguments);
                return new Proxy(data, {
                    get: function(target, prop) {
                        const val = target[prop];
                        if (typeof prop === 'string' && !isNaN(Number(prop))) {
                            return val + (Math.random() - 0.5) * 0.0001;
                        }
                        return val;
                    }
                });
            };
            return buf;
        };
    }

    // --- Font enumeration protection via CSS.escape override ---
    const _origMeasureText = document.createElement('canvas').getContext('2d').measureText;
    if (CanvasRenderingContext2D && CanvasRenderingContext2D.prototype.measureText) {
        const _origCanvasMeasureText = CanvasRenderingContext2D.prototype.measureText;
        CanvasRenderingContext2D.prototype.measureText = function() {
            // Add micro-offset to width to break font fingerprint hashes
            const metrics = _origCanvasMeasureText.apply(this, arguments);
            return new Proxy(metrics, {
                get: function(target, prop) {
                    const val = target[prop];
                    if (typeof val === 'number') return val * (1 + Math.random() * 0.0002);
                    return val;
                }
            });
        };
    }
})();
