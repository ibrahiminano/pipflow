//
//  CleanTradingViewChart.swift
//  Pipflow
//
//  Clean TradingView Chart with only candlesticks - no indicators
//

import SwiftUI
import WebKit

struct CleanTradingViewChart: UIViewRepresentable {
    let symbol: String
    @State private var selectedTimeframe: ChartTimeframe = .h1
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        
        loadTradingViewChart(webView)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Update chart if needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func loadTradingViewChart(_ webView: WKWebView) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                body {
                    margin: 0;
                    padding: 0;
                    background: #000;
                    overflow: hidden;
                }
                #tradingview_widget {
                    width: 100vw;
                    height: 100vh;
                }
                .tradingview-widget-container {
                    width: 100%;
                    height: 100%;
                }
                .tradingview-widget-container__widget {
                    width: 100%;
                    height: 100%;
                }
            </style>
        </head>
        <body>
            <div id="tradingview_widget"></div>
            
            <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
            <script type="text/javascript">
                // Determine symbol with proper exchange prefix
                let symbolToUse = '\(symbol)';
                if (symbolToUse.includes('USD') && !symbolToUse.includes('BTC') && !symbolToUse.includes('ETH')) {
                    // Forex pairs
                    symbolToUse = 'FX:' + symbolToUse;
                } else if (symbolToUse.includes('BTC') || symbolToUse.includes('ETH')) {
                    // Crypto pairs
                    symbolToUse = 'BINANCE:' + symbolToUse;
                } else if (symbolToUse.includes('XAU')) {
                    // Gold
                    symbolToUse = 'TVC:' + symbolToUse;
                }
                
                // Initialize clean TradingView widget with NO indicators
                new TradingView.widget({
                    "autosize": true,
                    "symbol": symbolToUse,
                    "interval": "60",
                    "timezone": "Etc/UTC",
                    "theme": "dark",
                    "style": "1", // Candlestick chart
                    "locale": "en",
                    "toolbar_bg": "#000000",
                    "enable_publishing": false,
                    "hide_side_toolbar": false,
                    "allow_symbol_change": false,
                    "container_id": "tradingview_widget",
                    "studies": [], // NO STUDIES/INDICATORS
                    "show_popup_button": false,
                    "popup_width": "1000",
                    "popup_height": "650",
                    "overrides": {
                        // Chart styling
                        "mainSeriesProperties.style": 1, // Candlestick
                        "paneProperties.background": "#000000",
                        "paneProperties.vertGridProperties.color": "#1a1a1a",
                        "paneProperties.horzGridProperties.color": "#1a1a1a",
                        "scalesProperties.textColor": "#AAA",
                        
                        // Candlestick colors
                        "mainSeriesProperties.candleStyle.upColor": "#26a69a",
                        "mainSeriesProperties.candleStyle.downColor": "#ef5350",
                        "mainSeriesProperties.candleStyle.borderUpColor": "#26a69a",
                        "mainSeriesProperties.candleStyle.borderDownColor": "#ef5350",
                        "mainSeriesProperties.candleStyle.wickUpColor": "#26a69a",
                        "mainSeriesProperties.candleStyle.wickDownColor": "#ef5350",
                        
                        // Remove volume by default
                        "mainSeriesProperties.showVolume": false,
                        
                        // Clean look
                        "paneProperties.legendProperties.showLegend": false,
                        "paneProperties.topMargin": 5,
                        "paneProperties.bottomMargin": 5
                    },
                    "disabled_features": [
                        "header_symbol_search",
                        "header_compare",
                        "display_market_status",
                        "go_to_date",
                        "header_indicators", // Disable indicators button
                        "create_volume_indicator_by_default" // No volume by default
                    ],
                    "enabled_features": [
                        "hide_left_toolbar_by_default",
                        "move_logo_to_main_pane"
                    ],
                    "charts_storage_url": "https://saveload.tradingview.com",
                    "charts_storage_api_version": "1.1",
                    "client_id": "pipflow",
                    "user_id": "public_user",
                    "fullscreen": false,
                    "width": "100%",
                    "height": "100%",
                    "studies_overrides": {}
                });
            </script>
        </body>
        </html>
        """
        
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: CleanTradingViewChart
        
        init(_ parent: CleanTradingViewChart) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Chart loaded successfully
            print("TradingView chart loaded")
        }
    }
}

#Preview {
    CleanTradingViewChart(symbol: "EURUSD")
}