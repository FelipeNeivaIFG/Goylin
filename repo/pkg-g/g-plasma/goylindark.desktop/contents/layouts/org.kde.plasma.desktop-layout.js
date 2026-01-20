var plasma = getApiVersion(1);

// Desktop
var desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
	desktopsArray[j].wallpaperPlugin = "org.kde.slideshow";
	desktopsArray[j].currentConfigGroup = ["General"];
	desktopsArray[j].writeConfig("arrangement", "1");
	desktopsArray[j].writeConfig("iconSize", "2");
	desktopsArray[j].writeConfig("labelWidth", "0");
	desktopsArray[j].writeConfig("sortMode", "6");
	desktopsArray[j].currentConfigGroup = ["Wallpaper", "org.kde.slideshow", "General"];
	desktopsArray[j].writeConfig("SlideInterval", "3600");
	desktopsArray[j].writeConfig("SlidePaths", "/usr/share/goylin/backgrounds/");
}

// Panel
const panel = new Panel();

panel.location = "bottom";
panel.height = gridUnit * 2;
panel.hiding = "none";
panel.alignment = "center";
panel.floating = true;
panel.lengthMode = "fill";

panel.addWidget("org.kde.plasma.kickoff");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.pager");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.icontasks");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.panelspacer");
panel.addWidget("org.kde.plasma.calculator");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.digitalclock");
