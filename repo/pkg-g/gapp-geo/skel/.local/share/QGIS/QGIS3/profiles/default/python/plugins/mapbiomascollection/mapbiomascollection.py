# -*- coding: utf-8 -*-
"""
/***************************************************************************
Name                 : MapBiomas Collection
Description          : This plugin lets you get collection of mapping from MapBiomas Project(http://mapbiomas.org/).
Date                 : November, 2021
copyright            : (C) 2019 by Luiz Motta, Updated by Luiz Cortinhas (2020)
email                : motta.luiz@gmail.com, luiz.cortinhas@solved.eco.br

 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
"""

import urllib.parse
import urllib.request, json

from osgeo import gdal

from qgis.PyQt.QtCore import (
    Qt, QSettings, QLocale,
    QObject, pyqtSlot 
)
from qgis.PyQt.QtWidgets import (
    QWidget, QPushButton,
    QSlider, QLabel,
    QTreeWidget, QTreeWidgetItem,
    QVBoxLayout, QHBoxLayout
)
from qgis.PyQt.QtGui import (
    QColor, QPixmap, QIcon
)

from qgis.core import (
    QgsApplication, Qgis, QgsProject,
    QgsRasterLayer,
    QgsTask
)
from qgis.gui import QgsGui, QgsMessageBar, QgsLayerTreeEmbeddedWidgetProvider

class MapBiomasCollectionWidget(QWidget):
    classRef = ''
    @staticmethod
    def getParentColor(item):
        if item['parent'] == '0' and item['status'] == False:
            return 'FFFFFF'
        if item['status']:
            return item['color']
        else:
            return MapBiomasCollectionWidget.getParentColor(MapBiomasCollectionWidget.classRef[item['parent']])

    @staticmethod
    def getUrl(url, version, year, l_class_id,classRef):
        MapBiomasCollectionWidget.classRef = classRef
        l_strClass = [ str(item) for item in l_class_id ]
        for item in MapBiomasCollectionWidget.classRef.keys():
            MapBiomasCollectionWidget.classRef[item]['status'] = False
        for item in l_strClass:
            MapBiomasCollectionWidget.classRef[item]['status'] = True
        #ENV Percorredor!
        env = 'env='
        for item in MapBiomasCollectionWidget.classRef.keys():
            classID = item
            classID_opacity = str(classID)+'_o'
            opacity = '1'
            color = MapBiomasCollectionWidget.getParentColor(MapBiomasCollectionWidget.classRef[item])
            if color == 'FFFFFF':
                opacity = '0'
            env = env + f'{classID}:{color};{classID_opacity}:{opacity};'
        params = {
            'IgnoreGetFeatureInfoUrl': '1',
            'IgnoreGetMapUrl': '1',
            'service': 'WMS',
            'styles': 'solved:mapbiomas_legend',
            'request': 'GetMap',
            'format': 'image/png', # image/png8
            'layers': 'mapbiomas_'+str(year),
            'crs': 'EPSG:4326',
            # 'stepHeight':'256',
            # 'stepWidth':'256',
            # 'maxHeight':'256',
            # 'maxWidth':'256',
            # 'dpiMode':'7',
            # 'featureCount':'10'
        }
       
        paramsWms = '&'.join( [ f"{k}={v}" for k,v in params.items() ] )
        paramsQuote = f""
        paramsQuote = f"{paramsQuote}&transparent=true&tiled=true&version=1.1.1&crs=EPSG:4326&LAYERS=mapbiomas_"+str(year)
        paramsQuote = urllib.parse.quote( f"{paramsQuote}&exceptions=application/vnd.ogc.se_inimage&years={year}&{env}&classification_ids=" )# a ordem importa
        paramClassification = ','.join( l_strClass )
        msg = f"{paramsWms}&url={url}?{paramsQuote}{paramClassification}"
        return f"{paramsWms}&url={url}?{paramsQuote}{paramClassification}"

    def __init__(self, layer, data):
        def getYearClasses():
            def getYear():
                values = [ item for item in paramsSource if item.find('years=') > -1]
                return self.maxYear if not len( values ) == 1 else int( values[0].split('=')[1] )

            def getClasses():
                values = [ item for item in paramsSource if item.find('classification_ids=') > -1 ]
                if (not len( values ) == 1) or (values[0] == 'classification_ids='):
                    return [] 
                else :
                    return [ int( item ) for item in values[0].split('=')[1].split(',') ]

            paramsSource = urllib.parse.unquote( self.layer.source() ).split('&')
            return getYear(), getClasses()

        def setGui(classes):
            def createLayoutYear():
                lytYear = QHBoxLayout()
                lblTitleYear = QLabel( 'Year:', self )
                lblYear = QLabel( str( self.year ), self )
                lytYear.addWidget( lblTitleYear  )
                lytYear.addWidget( lblYear )
                return lytYear, lblYear

            def createLayoutSlider():
                def createButtonLimit(limitYear, sFormat, objectName):
                    label = sFormat.format( limitYear )
                    pb = QPushButton( label, self )
                    width = pb.fontMetrics().boundingRect( label ).width() + 7
                    pb.setMaximumWidth( width )
                    pb.setObjectName( objectName )
                    return pb

                def createSlider():
                    slider = QSlider( Qt.Horizontal, self )
                    #slider.setTracking( False ) # Value changed only released mouse
                    slider.setMinimum( self.minYear )
                    slider.setMaximum( self.maxYear )
                    slider.setSingleStep(1)
                    slider.setValue( self.year )
                    interval = int( ( self.maxYear - self.minYear) / 10 )
                    slider.setTickInterval( interval )
                    slider.setPageStep( interval)
                    slider.setTickPosition( QSlider.TicksBelow )
                    return slider

                lytSlider = QHBoxLayout()
                pbMin = createButtonLimit( self.minYear, "{} <<", 'minYear' )
                lytSlider.addWidget( pbMin )
                slider = createSlider()
                lytSlider.addWidget( slider )
                pbMax = createButtonLimit( self.maxYear, ">> {}", 'maxYear' )
                lytSlider.addWidget( pbMax )
                return lytSlider, slider, pbMin, pbMax

            def createTree(classes):
                def populateTreeJson(classes, itemRoot):
                    def createIcon(color):
                        color = QColor( color['r'], color['g'], color['b'] )
                        pix = QPixmap(16, 16)
                        pix.fill( color )
                        return QIcon( pix )

                    def createItem(itemRoot, name, class_id, flags, icon):
                        # WidgetItem
                        item = QTreeWidgetItem( itemRoot )
                        item.setText(0, name )
                        item.setData(0, Qt.UserRole, class_id )
                        checkState = Qt.Checked if class_id in self.l_class_id else Qt.Unchecked
                        item.setCheckState(0, checkState )
                        item.setFlags( flags )
                        item.setIcon(0, icon )
                        return item

                    flags = itemRoot.flags() | Qt.ItemIsUserCheckable
                    for k in classes:
                        class_id = classes[ k ]['id']
                        icon = createIcon( classes[ k ]['color'] )
                        itemClass = createItem( itemRoot, k, class_id, flags, icon )
                        if 'classes' in classes[ k ]:
                            populateTreeJson( classes[ k ]['classes'], itemClass )

                tree = QTreeWidget( self )
                tree.setSelectionMode( tree.NoSelection )
                tree.setHeaderHidden( True )
                itemRoot = QTreeWidgetItem( tree )
                itemRoot.setText(0, 'Classes')
                populateTreeJson( classes, itemRoot )
                return tree, itemRoot

            lytYear, lblYear  = createLayoutYear()
            lytSlider, slider, pbMin, pbMax = createLayoutSlider( )
            tree, itemClasses = createTree( classes )
            itemClasses.setExpanded( True )
            # Layout
            lyt = QVBoxLayout()
            lyt.addLayout( lytYear )
            lyt.addLayout( lytSlider )
            lyt.addWidget( tree )
            msgBar = QgsMessageBar(self)
            lyt.addWidget( msgBar )
            self.setLayout( lyt )


            return {
                'msgBar': msgBar,
                'lblYear': lblYear,
                'slider': slider,
                'pbMin': pbMin,
                'pbMax': pbMax,
                'tree': tree,
                'itemClasses': itemClasses
            }

        super().__init__()
        self.layer = layer
        self.version = data['version']
        self.url = data['url']
        self.minYear = data['years']['min']
        self.maxYear = data['years']['max']

        self.project = QgsProject.instance()
        self.root = self.project.layerTreeRoot()

        self.year, self.l_class_id = getYearClasses() # Depend self.maxYear
        self.valueYearLayer = self.year

        r = setGui( data['classes'] )
        self.msgBar = r['msgBar']
        self.lblYear = r['lblYear']
        self.slider = r['slider']
        self.pbMin = r['pbMin']
        self.pbMax = r['pbMax']
        self.tree = r['tree']
        self.itemClasses = r['itemClasses']

        # Connections
        self.slider.valueChanged.connect( self.on_yearChanged )
        self.slider.sliderReleased.connect( self.on_released )
        self.pbMin.clicked.connect( self.on_limitYear )
        self.pbMax.clicked.connect( self.on_limitYear )
        self.tree.itemChanged.connect( self.on_classChanged )

    def _uploadSource(self):
        def checkDataSource():
            url = self.getUrl( self.url, self.version, self.year, self.l_class_id, MapBiomasCollectionWidget.classRef )
            name = f"Collection {self.version} - {self.year}"
            args = [ url, name, self.layer.providerType() ]
            layer = QgsRasterLayer( *args )
            if not layer.isValid():
                msg = f"Error server {self.url}"
                return { 'isOk': False, 'message': msg }
            args += [ self.layer.dataProvider().ProviderOptions() ]
            return { 'isOk': True, 'args': args }

        self.setEnabled( False )
        r = checkDataSource()
        if not r['isOk']:
            self.msgBar.pushMessage( r['message'], Qgis.Critical, 4 )
            self.setEnabled( True )
            return
        self.layer.setDataSource( *r['args'] ) # The Widget will be create agai

    @pyqtSlot()
    def on_released(self):
        if self.valueYearLayer == self.year:
            return

        self._uploadSource()

    @pyqtSlot(int)
    def on_yearChanged(self, value):
        if value == self.year:
            return

        self.yearChanged = True
        self.year = value
        self.lblYear.setText( str( value ) )
        if not self.slider.isSliderDown(): # Keyboard
            self.valueYearLayer = self.year
            self._uploadSource()

    @pyqtSlot(bool)
    def on_limitYear(self, checked):
        year = self.maxYear if self.sender().objectName() == 'maxYear' else self.minYear
        if year == self.year:
            return

        self.year = year
        self.lblYear.setText( str( self.year ) )
        self.valueYearLayer = self.year
        self._uploadSource()

    @pyqtSlot(QTreeWidgetItem, int)
    def on_classChanged(self, item, column):
        value = item.data( column, Qt.UserRole)
        color = item.data( column, Qt.UserRole)
        status = item.checkState( column ) == Qt.Checked
        f = self.l_class_id.append if status else self.l_class_id.remove
        f( value )
        self._uploadSource()


class LayerMapBiomasCollectionWidgetProvider(QgsLayerTreeEmbeddedWidgetProvider):
    def __init__(self, data):
        super().__init__()
        self.data = data

    def id(self):
        return 'mapbiomascollection'

    def name(self):
        return "Layer MapBiomas Collection"

    def createWidget(self, layer, widgetIndex):
        return MapBiomasCollectionWidget( layer, self.data )

    def supportsLayer(self, layer):
        if not layer.providerType() == 'wms':
            return False
        source = urllib.parse.unquote( layer.source() ).split('&')
        host = f"url={self.data['url']}?map=wms/v/{self.data['version']}/classification/coverage.map"
        l_url = [ item for item in source if item.find( host ) > -1 ]
        return len( l_url ) > 0


class MapBiomasCollection(QObject):
    MODULE = 'MapBiomasCollection'
    def __init__(self, iface):
        def getConfig():
            def readUrlJson(locale):
                f_name = 'http://azure.solved.eco.br:90/mapbiomascollection_{locale}.json'
                isOk = True
                try:
                    name = f_name.format( locale=locale )
                    with urllib.request.urlopen(name) as url:
                        data = json.loads( url.read().decode() )
                except:
                    isOk = False
                
                r = { 'isOk': isOk }
                ( key, value ) = ( 'data', data )  if isOk else ( 'message', f"Missing file '{name}'" )
                r[ key ] = value
                return r

            overrideLocale = QSettings().value('locale/overrideFlag', False, type=bool)
            locale = QLocale.system().name() if not overrideLocale else QSettings().value('locale/userLocale', '')
            r = readUrlJson( locale )
            if r['isOk']:
                return r['data']

            if not r['isOk'] and locale == 'en_US':
                self.messageError = r['message']
                return None

            r = readUrlJson('en_US')
            if r['isOk']:
                return r['data']

            self.messageError = r['message']
            return None

        super().__init__()        
        self.msgBar = iface.messageBar()
        self.root = QgsProject.instance().layerTreeRoot()
        self.taskManager = QgsApplication.taskManager()
        self.messageError = ''
        self.data = getConfig() # If error, return None and set self.messageError
        self.widgetProvider = None

    def register(self):
        self.widgetProvider = LayerMapBiomasCollectionWidgetProvider( self.data )
        registry = QgsGui.layerTreeEmbeddedWidgetRegistry()
        if not registry.provider( self.widgetProvider.id() ) is None:
            registry.removeProvider( self.widgetProvider.id() )
        registry.addProvider( self.widgetProvider )

    def run(self):
        def createLayer(task, year, l_class_id):
            args = (self.data['url'], self.data['version'], year, l_class_id, self.data['classParents'])
            url = MapBiomasCollectionWidget.getUrl( *args )
            return ( url, f"Collection {self.data['version']} - {year}", 'wms' )

        def finished(exception, result=None):
            self.msgBar.clearWidgets()
            if not exception is None:
                msg = f"Error: Exception: {exception}"
                self.msgBar.pushMessage( self.MODULE, msg, Qgis.Critical, 4 )
                return
            layer = QgsRasterLayer( *result )
            if not layer.isValid():
                source = urllib.parse.unquote( layer.source() ).split('&')
                url = [ v for v in source if v.split('=')[0] == 'url' ][0]
                msg = f"!!!Error server: Get {url}"
                self.msgBar.pushCritical( self.MODULE, msg )
                return

            project = QgsProject.instance()
            totalEW = int( layer.customProperty('embeddedWidgets/count', 0) )
            layer.setCustomProperty('embeddedWidgets/count', totalEW + 1 )
            layer.setCustomProperty(f"embeddedWidgets/{totalEW}/id", self.widgetProvider.id() )
            project.addMapLayer( layer )
            root = project.layerTreeRoot()
            ltl = root.findLayer( layer )
            ltl.setExpanded(True)

        if self.data is None:
            self.msgBar.pushMessage( self.MODULE, self.messageError, Qgis.Critical, 0 )
            return
        
        msg = f"Adding layer collection from {self.data['url']}"
        msg = f"{msg}(version {self.data['version']})..."
        self.msgBar.pushMessage( self.MODULE, msg, Qgis.Info, 0 )
        # Task
        args = {
            'description': self.MODULE,
            'function': createLayer,
            'year': self.data['years']['max'],
            'l_class_id': [1, 10, 14, 22, 26, 27],
            'on_finished': finished
        }
        task = QgsTask.fromFunction( **args )
        self.taskManager.addTask( task )
