package com.ngxinteractive.cellphonedisco {

	import com.gestureworks.cml.core.CMLParser;
	import com.gestureworks.cml.elements.Album;
	import com.gestureworks.cml.elements.TouchContainer;
	import com.gestureworks.cml.elements.Video;
	import com.gestureworks.cml.utils.document;
	import com.gestureworks.core.GestureWorks;
	import com.gestureworks.events.GWGestureEvent;
	import com.ngxinteractive.dts.DTS;

	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.Timer;
	import flash.utils.setTimeout;

	[SWF(width = "1080", height = "1920", backgroundColor = "0x000000", frameRate = "30")]

	public class CellPhoneDisco extends GestureWorks {

		//****** Imported Fonts ******

		[Embed(source = "../../../../library/fonts/Lato-Heavy.ttf", fontFamily = 'LatoHeavy', mimeType = 'application/x-font-truetype', advancedAntiAliasing = 'true', embedAsCFF = 'false')]
		private var LatoHeavyImported: Class;

		[Embed(source = "../../../../library/fonts/Lato-Black.ttf", fontName = 'LatoBlack', mimeType = 'application/x-font-truetype', advancedAntiAliasing = 'true', embedAsCFF = 'false')]
		private var LatoBlackImported: Class;

		[Embed(source = "../../../../library/fonts/Lato-Medium.ttf", fontName = 'LatoMedium', mimeType = 'application/x-font-truetype', advancedAntiAliasing = 'true', embedAsCFF = 'false')]
		private var LatoMediumImported: Class;

		[Embed(source = "../../../../library/fonts/Lato-Regular.ttf", fontName = 'LatoRegular', mimeType = 'application/x-font-truetype', advancedAntiAliasing = 'true', embedAsCFF = 'false')]
		private var LatoRegularImported: Class;

		//****** Config Settings ******

		private var config: Object;
		private var config_path: String = "setup.json";

		//********** Timers ***********

		public var ctaTimerValue;
		private var ctaTimer: Timer;

		public var overlayTimerValue;
		private var overlayTimer: Timer;

		public var attractTimerValue;
		private var attractTimer: Timer;

		//******** Misc Vars **********

		public var currentOverlay: int = -1;
		public var previousPanel: int = 0;

		//********* Methods ***********

		public function CellPhoneDisco(): void {
			super();
			gml = "library/gml/gestures.gml";
			cml = "library/cml/main.cml";
			CMLParser.addEventListener(CMLParser.COMPLETE, cmlComplete);
			loadConfig();
		}

		private function cmlComplete(event: Event): void {
			trace("cmlComplete()");
			CMLParser.removeEventListener(CMLParser.COMPLETE, cmlComplete);
			trace(document.getElementById("title-txt").str);

			addListeners();

			ctaTimer = new Timer(ctaTimerValue);
			ctaTimer.addEventListener("timer", ctaTimerHandler);
			ctaTimer.start();

			attractTimer = new Timer(attractTimerValue);
			attractTimer.addEventListener("timer", attractTimerHandler);
			attractTimer.start();

			overlayTimer = new Timer(overlayTimerValue, 1);
			overlayTimer.addEventListener("timer", overlayTimerHandler);
		}

		private function addListeners(): void {
			stage.nativeWindow.addEventListener(Event.CLOSING, onCloseApplication);

			var infoButtons: Object = document.getElementsByClassName("infoicon");
			for each(var i: Object in infoButtons) {
				i.addEventListener(GWGestureEvent.TAP, infoButtonsGestureTapHandler);
			}

			var panelButtons: Object = document.getElementsByClassName("contentpanelbutton");
			for each(var p: Object in panelButtons) {
				p.addEventListener(GWGestureEvent.TAP, panelButtonsGestureTapHandler);
			}

			var overlayCloseButtons: Object = document.getElementsByClassName("overlayclose");
			for each(var c: Object in overlayCloseButtons) {
				c.addEventListener(GWGestureEvent.TAP, overlayCloseButtonsGestureTapHandler);
			}

			var contentPanels: Object = document.getElementsByClassName("overlayscreenbg");
			for each(var cp: Object in contentPanels) {
				cp.addEventListener(GWGestureEvent.TAP, overlayCloseButtonsGestureTapHandler);
			}

			var overlayVideos: Object = document.getElementsByClassName("overlayvideo");
			for each(var ov: Object in overlayVideos) {
				ov.addEventListener(GWGestureEvent.TAP, overlayVideoGestureTapHandler);
			}

			//Gestures implemented: 
			//drag, rotate, scale, drag-inertia, rotate-inertia, scale-inertia, hold, tap, double_tap, triple_tap 	
			document.getElementById("screen").addEventListener(GWGestureEvent.TAP, tapGestureManager);

			document.getElementById("attract").addEventListener(GWGestureEvent.TAP, attractGestureTapHandler);
			document.getElementById("attract").addEventListener(GWGestureEvent.FLICK, attractGestureTapHandler);

			document.getElementById("whatshapp").addEventListener(GWGestureEvent.TAP, infoButtonsGestureTapHandler);
		}

		//******* Timer Handlers ******

		private function ctaTimerHandler(event: TimerEvent): void {
			var album: Album = document.getElementById("cta-album");
			if (album.currentIndex == album.loopQueue.length - 1) {
				album.reset();
			} else {
				album.next();
			}
			ctaTimer.reset();
			ctaTimer.start();
		}

		private function attractTimerHandler(event: TimerEvent): void {
			trace("Attract timer Up");
			attractTimer.reset();

			//TODO: Check if panels have moved
			//Workaround not reading drag gesture on album
			var currentPanel: int = document.getElementById("content-album").currentIndex;
			if (currentPanel != previousPanel) {
				previousPanel = currentPanel;
				attractTimer.start();
				return;
			}

			var video: Video = document.getElementById("overlay" + currentOverlay + "-video");
			if (video != null && video.isPlaying) {
				attractTimer.start();
				return;
			} else {
				//Close info bubbles that were open
				closeAllInfoBubbles();				
				
				document.getElementById("screen").alpha = 0.25;
				document.getElementById("attract").visible = true;

				DTS.sendAttractStart();
			}
		}

		private function overlayTimerHandler(event: TimerEvent): void {
			closeOverlay();
		}

		//****** Gesture Handlers ******

		//Attract screen tap handler
		private function attractGestureTapHandler(event: GWGestureEvent): void {
			document.getElementById("screen").alpha = 1;
			document.getElementById("attract").visible = false;
			trace(DTS.getStatus());

			DTS.sendAttractBreak();
			restartAttractTimer();
		}

		
		/*Home Screen – Second Section
		(Middle section - grey with icons)*/
		private function infoButtonsGestureTapHandler(event: GWGestureEvent): void {
			trace(event.target.id);
			if (event.target.id == "whatshapp") {
				if (closeAllInfoBubbles()) {
					sendEvent(event.target.name, 'Close');
				}
			} else {
				var bubble = event.target.getElementById("whatshapp-infobubble");
				var visible: Boolean = bubble.visible;
				bubble.visible = !visible;
				if (visible) {
					sendEvent(event.target.name, 'Close');
				} else {
					sendEvent(event.target.name, 'Open');
				}
			}
		}
		
		//Close info bubbles that are open
		private function closeAllInfoBubbles() : Boolean{
			var infoBubbles: Object = document.getElementsByClassName("infobubble");
			var didClose: Boolean = false;
			for each(var ib: Object in infoBubbles) {
				if (ib.visible) {
					ib.visible = false;
					didClose = true;
				}
			}
			return didClose;
		}

		/*Home Screen – Third Section(Panels*)
		Tap handler*/
		private function panelButtonsGestureTapHandler(event: GWGestureEvent): void {
			var album: Album = document.getElementById("content-album");
			var albumIndex: int = album.currentIndex + 1;
			if (albumIndex >= album.loopQueue.length) {
				albumIndex = 0;
			}
			var buttonId: String = event.target.id;
			var buttonPanelNo: int = parseInt(buttonId.substr(buttonId.length - 8, 1), 10);

/*			if (albumIndex == buttonPanelNo) {*/
				currentOverlay = buttonPanelNo;

				document.getElementById("screen").alpha = 0.25;
				document.getElementById("overlay" + currentOverlay).visible = true;

				var video = document.getElementById("overlay" + currentOverlay + "-video");
				if (video != null) {
					var father = video.parent;
					father.getElementById("overlay" + currentOverlay + "-video").seek(0);
					father.getElementById("playbutton").visible = true;
					father.getElementById("pausebutton").visible = false;
				}
				overlayTimer.start();

				sendEvent(document.getElementById("overlay" + buttonPanelNo).name, 'Open');
			//}
		}
		
		private function overlayVideoGestureTapHandler(event: GWGestureEvent): void {
			//Hide play button
			event.target.getElementById("playbutton").visible = false;
			var video: Object = document.getElementById("overlay" + currentOverlay + "-video");
			if (video != null && video.isPlaying) {
				video.pause();
				//Show playbutton
				event.target.getElementById("playbutton").visible = true;
				sendEvent(video.name, 'PauseVideo');
			} else {
				//Hide playbutton
				event.target.getElementById("playbutton").visible = false;
				video.resume();
				sendEvent(video.name, 'PlayVideo');
			}
		}

		private function overlayCloseButtonsGestureTapHandler(event: GWGestureEvent): void {
			closeOverlay();
		}

		private function tapGestureManager(event: GWGestureEvent): void {
			trace("Tap Gesture Detected " + event.target.id);
			if (currentOverlay > -1) {
				closeOverlay();
			}
		}

		//****** Helper Methods *******

		private function restartAttractTimer(): void {
			attractTimer.reset();
			attractTimer.start();
		}

		private function closeOverlay(): void {
			document.getElementById("overlay" + currentOverlay).visible = false;
			document.getElementById("screen").alpha = 1;

			var video: Video = document.getElementById("overlay" + currentOverlay + "-video");
			if (video != null && video.isPlaying) {
				video.stop();
				sendEvent(video.name, 'StopVideo');
			}
			sendEvent(document.getElementById("overlay" + currentOverlay).name, 'Close');

			overlayTimer.reset();
			currentOverlay = -1;
		}

		private function loadConfig(): void {
			var urlloader: URLLoader = new URLLoader();
			var request: URLRequest = new URLRequest();
			request.url = config_path;
			urlloader.addEventListener(Event.COMPLETE, onConfigLoaded);
			urlloader.load(request);
		}

		private function onConfigLoaded(e): void {
			var urlloader: URLLoader = URLLoader(e.target);
			config = JSON.parse(urlloader.data);
			DTS.setupTracking(config);
			DTS.sendLoaded();

			ctaTimerValue = config.ctaTimerValue;
			overlayTimerValue = config.overlayTimerValue;
			attractTimerValue = config.attractTimerValue;
		}

		private function sendEvent(path: String, actionlabel: String): void {
			DTS.sendScreen(actionlabel, path+":"+actionlabel);
			if (path.indexOf("instance") >= 0){
				trace("Here we go");
			}
			attractTimer.reset();
			attractTimer.start();
		}

		private function onCloseApplication(e): void {
			if (e) {
				e.preventDefault();
			}
			DTS.sendQuit();
			setTimeout(exit, 0.2);
		}

		private function exit(): void {
			NativeApplication.nativeApplication.exit();
		}

	}
}