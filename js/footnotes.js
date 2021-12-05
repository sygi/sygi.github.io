$(document).ready(function() {
	Footnotes.setup();
});

var Footnotes = {
	footnotetimeout: false,
	iOS: function() {
		var agent = navigator.userAgent.toLowerCase();
		return (
			agent.indexOf('iphone') >= 0
		||
			agent.indexOf('ipad') >= 0
		||
			agent.indexOf('ipod') >= 0
		||
			agent.indexOf('Android') >= 0
		);
	},
	setup: function() {
		var footnotelinks = $(".footnoteRef")
		
		footnotelinks.unbind('mouseover',Footnotes.footnoteover);
		footnotelinks.unbind('mouseout',Footnotes.footnoteoout);
		
		footnotelinks.bind('mouseover',Footnotes.footnoteover);
		footnotelinks.bind('mouseout',Footnotes.footnoteoout);
	},
	footnoteover: function() {
		clearTimeout(Footnotes.footnotetimeout);
		$('#footnotediv').stop();
		$('#footnotediv').remove();
		
		var id = $(this).attr('href').substr(1);
		var refid = "#" + id.substr(0, 2) + "ref" + id.substr(2);
		var position = $(this).offset();
	
		var d = document.createElement('div');
		var div = $(d);
		div.attr('id','footnotediv');
		
		if(Footnotes.iOS()) {
			// don't bind the mouseover event here; otherwise, Safari for iOS
			// will only trigger the mouseover event when the user taps the
			// popup, and will not fire the remaining events
			// see here: http://developer.apple.com/library/ios/#DOCUMENTATION/AppleApplications/Reference/SafariWebContent/HandlingEvents/HandlingEvents.html
			div.bind('click',Footnotes.remove);
		} else {
			div.bind('mouseover',Footnotes.divover);
			div.bind('mouseout',Footnotes.footnoteoout);
		}

		var el = document.getElementById(id).cloneNode(true);
		var maybe_inner_el = el.firstChild;
		if (maybe_inner_el) {
			var maybe_backlink = maybe_inner_el.lastChild;
			if (maybe_backlink.getAttribute && maybe_backlink.getAttribute("href") === refid){
				maybe_inner_el.removeChild(maybe_backlink);
			}
		}
		div.html('<div>'+$(el).html()+'</div>');
		
		$(document.body).append(div);

		var left = position.left;
		if(left + 420  > $(window).width() + $(window).scrollLeft())
			left = $(window).width() - 420 + $(window).scrollLeft();
		var top = position.top+20;
		if(top + div.height() > $(window).height() + $(window).scrollTop())
			top = position.top - div.height() - 15;
		div.css({
      position:'absolute',
			left:left,
			top:top,
			opacity:0.97
		});
	},
	footnoteoout: function() {
		Footnotes.footnotetimeout = setTimeout(function() {
			Footnotes.remove();
		},1000);
	},
	remove: function() {
		$('#footnotediv').animate({
			opacity: 0
		}, 1000, function() {
			$('#footnotediv').remove();
		});
	},
	divover: function() {
		clearTimeout(Footnotes.footnotetimeout);
		$('#footnotediv').stop();
		$('#footnotediv').css({
				opacity: 0.97
		});
	}
}
