var plasma = getApiVersion(1);

var layout = {
    "desktops": [
        {
            "applets": [
            ],
            "config": {
                "/": {
                    "ItemGeometriesHorizontal": "",
                    "formfactor": "0",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.slideshow"
                },
                "/General": {
                    "ToolBoxButtonState": "topcenter",
                    "ToolBoxButtonX": "495",
                    "arrangement": "1",
                    "iconSize": "2",
                    "labelWidth": "0",
                    "previewPlugins": "appimagethumbnail,audiothumbnail,cursorthumbnail,fontthumbnail,textthumbnail,ffmpegthumbs,djvuthumbnail,blenderthumbnail,mobithumbnail,gsthumbnail,rawthumbnail,comicbookthumbnail,marble_thumbnail_osm,marble_thumbnail_kmz,marble_thumbnail_geojson,marble_thumbnail_gpx,marble_thumbnail_kml,opendocumentthumbnail,kraorathumbnail,ebookthumbnail,windowsexethumbnail,imagethumbnail,windowsimagethumbnail,exrthumbnail,jpegthumbnail,svgthumbnail,mltpreview,directorythumbnail,marble_thumbnail_shp",
                    "sortMode": "6"
                },
                "/Wallpaper/org.kde.slideshow/General": {
                    "SlideInterval": "3600",
                    "SlidePaths": "/usr/share/goylin/backgrounds/"
                },
            },
            "wallpaperPlugin": "org.kde.slideshow"
        }
    ],
    "panels": [
        {
            "alignment": "center",
            "applets": [
                // {
                //     "config": {
                //         "/General": {
                //             "show_lockScreen": "false",
                //             "show_requestLogout": "true",
                //             "show_requestShutDown": "false"
                //         }
                //     },
                //     "plugin": "org.kde.plasma.lock_logout"
                // },
                {
                    "config": {
                        "/General": {
                            "applicationsDisplay": "0",
                            "favoriteSystemActions": "logout",
                            "favoritesPortedToKAstats": "true",
                            "icon": "/usr/share/goylin/icons/goylin.svg",
                            "primaryActions": "1",
                            "systemFavorites": "logout,save-session"
                        },
                    },
                    "plugin": "org.kde.plasma.kickoff"
                },
                {
                    "config": {
                        "/General": {
                            "launchers": "",
                            "showOnlyCurrentActivity": "false",
                            "showOnlyCurrentDesktop": "false"
                        }
                    },
                    "plugin": "org.kde.plasma.icontasks"
                },
                {
                    "plugin": "org.kde.plasma.marginsseparator"
                },
                {
                    "plugin": "org.kde.plasma.digitalclock"
                },
                {
                    "plugin": "org.kde.plasma.systemtray"
                }
            ],
            "config": {
                "/": {
                    "formfactor": "2",
                    "immutability": "1",
                    "lastScreen": "0",
                    "wallpaperplugin": "org.kde.slideshow"
                },
            },
            "height": 2.5,
            "hiding": "windowscover",
            "location": "bottom",
            "maximumLength": 80,
            "minimumLength": 60,
            "offset": 0
        }
    ],
    "serializationFormatVersion": "1"
}
;

plasma.loadSerializedLayout(layout);
