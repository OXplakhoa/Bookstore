// Flash Sale Countdown Timer
(function () {
    function pad(n) { 
        return n < 10 ? '0' + n : n; 
    }

    function renderCountdown(el, msLeft) {
        if (msLeft <= 0) {
            el.textContent = 'Đã kết thúc';
            el.classList.add('text-muted');
            el.classList.remove('countdown-active');
            el.dispatchEvent(new CustomEvent('flashsale:expired', { bubbles: true }));
            return false;
        }

        var totalSeconds = Math.floor(msLeft / 1000);
        var days = Math.floor(totalSeconds / 86400);
        var hours = Math.floor((totalSeconds % 86400) / 3600);
        var minutes = Math.floor((totalSeconds % 3600) / 60);
        var seconds = totalSeconds % 60;

        var parts = [];
        if (days > 0) parts.push(days + ' ngày');
        if (hours > 0 || days > 0) parts.push(pad(hours) + 'h');
        parts.push(pad(minutes) + 'm', pad(seconds) + 's');

        el.textContent = 'Kết thúc trong ' + parts.join(' ');
        el.classList.add('countdown-active');
        return true;
    }

    function initOne(el) {
        var endIso = el.getAttribute('data-countdown-end');
        if (!endIso) return;

        var end = new Date(endIso);
        if (isNaN(end.getTime())) {
            console.error('Invalid countdown date:', endIso);
            return;
        }

        function tick() {
            var now = new Date();
            var msLeft = end.getTime() - now.getTime();
            if (!renderCountdown(el, msLeft)) {
                clearInterval(timer);
            }
        }

        tick();
        var timer = setInterval(tick, 1000);
    }

    window.initFlashSaleCountdowns = function () {
        document.querySelectorAll('[data-countdown-end]').forEach(initOne);
    };

    // Auto-initialize on page load
    document.addEventListener('DOMContentLoaded', window.initFlashSaleCountdowns);

    // Optional: Listen for expired events to refresh page or update UI
    document.addEventListener('flashsale:expired', function(e) {
        console.log('Flash sale expired on element:', e.target);
        // Optional: Show a message or refresh the page
        // setTimeout(function() { location.reload(); }, 2000);
    });
})();
