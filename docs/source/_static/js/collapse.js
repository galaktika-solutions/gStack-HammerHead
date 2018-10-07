// Anonymous "self-invoking" function
(function() {
    // Load the script
    var script = document.createElement("SCRIPT");
    script.src = 'https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js';
    script.type = 'text/javascript';
    script.onload = function() {
        var $ = window.jQuery;
        function collapse_dd(){
            var item = $(this).parent();
            if (item.hasClass('collapsed')) {
                item.removeClass('collapsed')
                item.children('dd').show('fast')
            } else {
                item.addClass('collapsed')
                item.children('dd').hide('fast')
            }
            return false;
        }
        $(document).ready(function() {
            $('dl.class > dt, dl.data > dt').click(collapse_dd)

            $('a').click(function(e) {
                e.stopPropagation();
            })

            if (window.location.hash.length != 0) {
                base = window.location.hash.replace(/\./g, '\\.');
                base = $(base);
                base.removeClass('collapsed');
                base.parents('dd').show();
                base.parents('dl').removeClass('collapsed');
                base.siblings('dd').show();
            }
        });
    };
    document.getElementsByTagName("head")[0].appendChild(script);
})();
