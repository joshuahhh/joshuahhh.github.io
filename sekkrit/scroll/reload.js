if(!window.reloadRunning) {
	window.reloadRunning = true;

	var LOG_RELOAD = false;

	var html = "";
	var firstCheck = true;

	var check = function () {
		if (LOG_RELOAD) console.log("checking");
		d3.text(document.URL, function(response) {
			if (firstCheck) {
				html = response;
				firstCheck = false;
			} else {
				if (html != response) {
					if (LOG_RELOAD) console.log("changed!");
					document.open();
					document.write(response);
					document.close();
					html = response;

					setTimeout(function () {
						console.log("queueing");
						MathJax.Hub.Queue(["Typeset", MathJax.Hub, document.body]);
					}, 100);
				}
			}
		});
	};
	setInterval(check, 500);
}
