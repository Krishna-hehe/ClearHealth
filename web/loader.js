window.onload = function () {
    // Check for Flutter engine periodically
    var checkInterval = setInterval(function () {
        // 'flt-glass-pane' is commonly used by Flutter Web.
        // We also check if the body has significantly more children (Flutter adding itself)
        if (document.querySelector('flt-glass-pane') || document.body.children.length > 3) {
            removeLoader();
        }
    }, 100);

    // Failsafe: Remove loader after 4 seconds (Flutter startup usually < 2s)
    setTimeout(removeLoader, 4000);

    function removeLoader() {
        clearInterval(checkInterval);
        var loader = document.getElementById('app-loading');
        if (loader) {
            loader.classList.add('fade-out');
            setTimeout(() => {
                loader.style.display = 'none';
            }, 500); // Wait for transition
        }
    }
};

// Configure Flutter Web to use HTML renderer instead of CanvasKit
// This fixes font rendering issues and works better with CSP
window.flutterConfiguration = {
    renderer: "html"
};
