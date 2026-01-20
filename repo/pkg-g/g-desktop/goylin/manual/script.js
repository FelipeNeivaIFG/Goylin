		function toggleTab(tabId) {
				var tabContent = document.getElementById(tabId);
				if (tabContent.style.display === "block") {
					tabContent.style.display = "none";
				} else {
					tabContent.style.display = "block";
				}
		}
		// Add keyboard accessibility
		document.querySelectorAll('.tab').forEach(tab => {
			tab.addEventListener('keydown', (e) => {
				if (e.key === 'Enter' || e.key === ' ') {
					e.preventDefault();
					tab.click();
				}
			});
		});