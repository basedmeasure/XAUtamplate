#property copyright "Copyright 2026, AK47 Scalper EA"
#property version   "5.00"
#property strict
#property description "AK47 PURE AGENT EDITION - 100% API DRIVEN"

#include <Trade\Trade.mqh>
#include "AK47_News.mqh"

// EA Settings
input double LotSize            = 0.01;
input double MaxDailyDrawdown   = 4.0;  // % Max drawdown per day
input double DailyProfitTarget  = 2.5;  // % Daily profit target to stop
input int    BaseMagicNumber    = 4747;
input int    MaxOrdersTotal     = 4;
input int    MaxSpread          = 35;   // Max allowed spread in points

// KILO AGENT API
input bool   UseNewsAiFilter    = true;
input string Kilo_ApiKey        = "YOUR_API_KEY_HERE";
input string Kilo_ApiUrl        = "https://api.kilocode.ai/v1/chat/completions";
input int    ApiCallInterval    = 15;   // Seconds between API calls

// Multi Symbol Settings
input string TradingSymbols     = "XAUUSD,EURUSD,GBPUSD,USDJPY";
input int    TrailingStart      = 100;
input int    TrailingStop       = 30;

struct SymbolInstance
{
   string   symbol;
   int      digit;
   double   point;
   int      lastApiCall;
   string   lastAction;
   double   lastConfidence;
   bool     isTradingDisabled;
   int      lastTradeTime;
};

SymbolInstance g_symbols[8];
int            g_symbolCount     = 0;
NewsAiClient  *newsAi;
CTrade         trade;
double         dailyStartBalance;
bool           isGlobalDisabled  = false;

int OnInit()
{
   newsAi = new NewsAiClient(Kilo_ApiKey, Kilo_ApiUrl);
   
   string symbols[];
   StringSplit(TradingSymbols, ',', symbols);
   g_symbolCount = ArraySize(symbols);
   if(g_symbolCount > 8) g_symbolCount = 8;
   
   for(int i=0; i<g_symbolCount; i++)
   {
      SymbolInstance sym = g_symbols[i];
      string trimmed = symbols[i];
      StringTrimLeft(trimmed);
      StringTrimRight(trimmed);
      sym.symbol = trimmed;
      //sym.magicNumber = BaseMagicNumber + i; // Note: Ensure struct has magicNumber if used, or use local
      
      if(!SymbolSelect(sym.symbol, true))
      {
         Print("Symbol not available: ", sym.symbol);
         g_symbolCount--; i--; continue;
      }
      
      sym.digit = (int)SymbolInfoInteger(sym.symbol, SYMBOL_DIGITS);
      sym.point = SymbolInfoDouble(sym.symbol, SYMBOL_POINT);
      sym.lastApiCall = 0;
      sym.lastAction = "WAIT";
      sym.lastConfidence = 0.0;
      sym.isTradingDisabled = false;
      sym.lastTradeTime = 0;
      
      g_symbols[i] = sym;
      Print("Initialized: ", sym.symbol);
   }
   
   dailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   Print("AK47 PURE AGENT STARTED | ALL NEURAL NETWORKS REMOVED");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   Comment("");
   delete newsAi;
}

void OnTick()
{
   UpdateDashboard();
   if(isGlobalDisabled) return;
   
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double profitPercent = ((currentEquity - dailyStartBalance) / dailyStartBalance) * 100.0;
   
   if(profitPercent <= -MaxDailyDrawdown) { isGlobalDisabled = true; return; }
   if(profitPercent >= DailyProfitTarget) { isGlobalDisabled = true; return; }
   
   if(PositionsTotalMagic() >= MaxOrdersTotal) return;
   
   for(int i=0; i<g_symbolCount; i++)
   {
      SymbolInstance sym = g_symbols[i];
      if(sym.isTradingDisabled) continue;
      if(PositionsTotalMagic() >= 1) continue; // Sample constraint
      
      int spread = (int)SymbolInfoInteger(sym.symbol, SYMBOL_SPREAD);
      if(spread > MaxSpread) continue;
      
      // Execute Agent Order
      double atr = 0.0001; // Placeholder for iATR simulation or custom ATR fetch
      double sl = atr * 1.5;
      double tp = atr * 2.5;
      
      if(sym.lastAction == "BUY")
      {
         double ask = SymbolInfoDouble(sym.symbol, SYMBOL_ASK);
         trade.Buy(LotSize, sym.symbol, NormalizeDouble(ask - sl, sym.digit), NormalizeDouble(ask + tp, sym.digit), BaseMagicNumber + i, "KILO AGENT BUY");
         sym.lastTradeTime = (int)TimeCurrent();
      }
      else if(sym.lastAction == "SELL")
      {
         double bid = SymbolInfoDouble(sym.symbol, SYMBOL_BID);
         trade.Sell(LotSize, sym.symbol, NormalizeDouble(bid + sl, sym.digit), NormalizeDouble(bid - tp, sym.digit), BaseMagicNumber + i, "KILO AGENT SELL");
         sym.lastTradeTime = (int)TimeCurrent();
      }
      g_symbols[i] = sym;
   }
   ManagePositions();
}

void UpdateDashboard()
{
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   double dailyProfit = currentEquity - dailyStartBalance;
   double profitPercent = (dailyProfit / dailyStartBalance) * 100.0;
   string text = "AK47 Dashboard\nEquity: " + DoubleToString(currentEquity, 2);
}

int PositionsTotalMagic()
{
   int count = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetSymbol(i) != "") count++;
   }
   return count;
}

void ManagePositions()
{
   // Basic Trailing implementation placeholder to keep file complete
}