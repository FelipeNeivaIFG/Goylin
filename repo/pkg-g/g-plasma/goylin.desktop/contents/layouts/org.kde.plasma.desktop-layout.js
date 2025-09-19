var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
            ],
            "config": {
                "/": {
                    "wallpaperplugin": "org.kde.slideshow"
                },
                "/General": {
                    "arrangement": "1",
                    "iconSize": "2",
                    "labelWidth": "0",
                    "sortMode": "6"
                },
                "/Wallpaper/org.kde.slideshow/General": {
			"SlideInterval": "3601",
			"SlidePaths": "/usr/share/goylin/backgrounds/"
                }
            },
            "wallpaperPlugin": "org.kde.slideshow"
        }
    ],
   "serializationFormatVersion": "1"
};

plasma.loadSerializedLayout(layout);

// Panel
var panel = new Panel

panel.height = 2 * Math.floor(gridUnit * 2 / 2)
panel.hiding = "none"
panel.alignment = "center"
panel.floating = 1
panel.lenghtMode = "fill"

panel.addWidget("org.kde.plasma.kickoff")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.pager")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.icontasks")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.panelspacer")
panel.addWidget("org.kde.plasma.calculator")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.systemtray")
panel.addWidget("org.kde.plasma.marginsseparator")
panel.addWidget("org.kde.plasma.digitalclock")
