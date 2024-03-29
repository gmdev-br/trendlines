//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "GreenDog"
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "TrendLines"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   2

enum enum_hhll {
   enableAll,
   enableUp,
   enableDown
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES         inputPeriodo = PERIOD_CURRENT;
input string                  inputAtivo = "";
input int                     LevDP = 2;       // Fractal Period or Levels Demar Pint
input int                     qSteps = 40;     // Number  Trendlines per UpTrend or DownTrend
input int                     BackStep = 0;  // Number of Steps Back
input int                     showBars = 10000; // Bars Back To Draw
input int                     ArrowCodeUp = 233;
input int                     ArrowCodeDown = 234;
input bool                    plotMarkers = false;
input int                     historicBars = 300;
input color                   UpTrendColorHistoric = clrLime;
input color                   DownTrendColorHistoric = clrRed;
input color                   UpTrendColorRecent = clrDodgerBlue;
input color                   DownTrendColorRecent = clrOrange;
input color                   buyFractalColor = clrLime;
input color                   sellFractalColor = clrRed;
input int                     colorFactor = 160;
input int                     TrendlineWidth = 1;
input ENUM_LINE_STYLE         TrendlineStyle = STYLE_SOLID;
input string                  UniqueID  = "trendline"; // Indicator unique ID
input int                     WaitMilliseconds = 10000;  // Timer (milliseconds) for recalculation
input double                  fatorLimitadorHistoric = 5;
input double                  fatorLimitadorRecent = 5;
input double                  dolar1 = 5.1574;
input double                  dolar2 = 5.3952;
input bool reverse = true;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Buf1[], Fractal1[];
double Buf2[], Fractal2[];
double precoAtual;

string ativo;
int _showBars = showBars;
ENUM_TIMEFRAMES periodo;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {

   ativo = inputAtivo;
   StringToUpper(ativo);
   if (ativo == "")
      ativo = _Symbol;

   periodo = inputPeriodo;
   _lastOK = false;

   SetIndexBuffer(0, Fractal1, INDICATOR_DATA);
   ArraySetAsSeries(Fractal1, true);

   SetIndexBuffer(1, Fractal2, INDICATOR_DATA);
   ArraySetAsSeries(Fractal2, true);

   SetIndexBuffer(2, Buf1, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf1, true);

   SetIndexBuffer(3, Buf2, INDICATOR_CALCULATIONS);
   ArraySetAsSeries(Buf2, true);

   if (plotMarkers) {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_ARROW);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
   } else {
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   }

   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);

   PlotIndexSetInteger(0, PLOT_LINE_COLOR, sellFractalColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, buyFractalColor);

   PlotIndexSetInteger(0, PLOT_ARROW, ArrowCodeDown);
   PlotIndexSetInteger(1, PLOT_ARROW, ArrowCodeUp);

   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   EventSetMillisecondTimer(WaitMilliseconds);
   //Update();

   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int  reason) {

   delete(_updateTimer);
   ObjectsDeleteAll(0, UniqueID);
   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   long totalRates = SeriesInfoInteger(ativo, PERIOD_CURRENT, SERIES_BARS_COUNT);
   double onetick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   ArrayInitialize(Buf1, 0.0);
   ArrayInitialize(Buf2, 0.0);
   ArrayInitialize(Fractal1, 0.0);
   ArrayInitialize(Fractal2, 0.0);

   precoAtual = iClose(ativo, PERIOD_CURRENT, 0);

   static datetime prevTime = 0;
//if(prevTime != iTime(_Symbol, PERIOD_CURRENT, 0)) { // New Bar
   int cnt = 0;
   if(_showBars == 0 || _showBars > totalRates - 1)
      _showBars = totalRates - 1;

   for(cnt = _showBars; cnt > LevDP; cnt--) {
      Buf1[cnt] = DemHigh(cnt, LevDP);
      Buf2[cnt] = DemLow(cnt, LevDP);
      Fractal1[cnt] =  Buf1[cnt];
      Fractal2[cnt] =  Buf2[cnt];
   }
   for(cnt = 1; cnt <= qSteps; cnt++)
      (TDMain(cnt));

//prevTime = iTime(_Symbol, PERIOD_CURRENT, 0);
//}
   ChartRedraw();

   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double &price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {
   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();
      //Print("Trendlines " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      EventSetMillisecondTimer(WaitMilliseconds);

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//| Returns the name of the day of the week                          |
//+------------------------------------------------------------------+
string DayOfWeek(const datetime time) {
   MqlDateTime dt;
   string day = "";
   TimeToStruct(time, dt);

   return dt.day_of_week;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TDMain(int Step) {
   int H1, H2, L1, L2;
   string Rem;
   bool historic = 0;

   if (DownTrendColorRecent != clrNONE || DownTrendColorHistoric != clrNONE) {
// DownTrendLines
      H1 = GetTD(Step + BackStep, Buf1);
      H2 = GetNextHighTD(H1, enableDown);

      if(H1 < 0 || H2 < 0) {
         //Print("Demark: Not enough bars on the chart for construction");
      } else {
         if (H2 > historicBars || H1 > historicBars) {
            Rem = UniqueID + "_down_historic_" + IntegerToString(Step);
            historic = 1;
         } else if (H2 <= historicBars || H1 <= historicBars) {
            Rem = UniqueID + "_down_recent_" + IntegerToString(Step);
            historic = 0;
         }

         ObjectDelete(0, Rem);
         double preco1 = iHigh(ativo, periodo, H2);
         double preco2 = iHigh(ativo, periodo, H1);

         ObjectCreate(0, Rem, OBJ_TREND, 0, iTime(ativo, periodo, H2), preco1, iTime(ativo, periodo, H1), preco2);
         ObjectSetInteger(0, Rem, OBJPROP_RAY_RIGHT, true);
         //int r = MathRandRange(0, 255);
         //int g = MathRandRange(0, 160);
         //int b = MathRandRange(0, 160);
         //ObjectSetInteger(0, Rem, OBJPROP_COLOR, StringToColor(255 + "," + g + "," + b));
         //int today_time = DayOfWeek(iTime(ativo, periodo, 0));
         //int trend_time = DayOfWeek(iTime(ativo, periodo, H2));

         ObjectSetInteger(0, Rem, OBJPROP_COLOR, DownTrendColorRecent);
         if (H2 > historicBars || H1 > historicBars)
            ObjectSetInteger(0, Rem, OBJPROP_COLOR, DownTrendColorHistoric);

         ObjectSetInteger(0, Rem, OBJPROP_WIDTH, TrendlineWidth);
         ObjectSetInteger(0, Rem, OBJPROP_STYLE, TrendlineStyle);
         //string s = "Dolarizado 1: " + DoubleToString(dolar1 * preco2, 0) +
         //           "\nDolarizado 2: " + DoubleToString(dolar2 * preco2, 0);
         //ObjectSetString(0, Rem, OBJPROP_TOOLTIP, s);
      }

      filterTrend(Rem, historic);
   }

   if (UpTrendColorRecent != clrNONE || UpTrendColorHistoric != clrNONE) {
// UpTrendLines
      L1 = GetTD(Step + BackStep, Buf2);
      L2 = GetNextLowTD(L1, enableUp);

      if(L1 < 0 || L2 < 0) {
         //Print("Demark: Not enough bars on the chart for construction");
      } else {
         if (L2 > historicBars || L1 > historicBars) {
            Rem = UniqueID + "_up_historic_" + IntegerToString(Step);
            historic = 1;
         } else if (L2 <= historicBars || L1 <= historicBars) {
            Rem = UniqueID + "_up_recent_" + IntegerToString(Step);
            historic = 0;
         }

         ObjectDelete(0, Rem);
         double preco1 = iLow(ativo, periodo, L2);
         double preco2 = iLow(ativo, periodo, L1);

         ObjectCreate(0, Rem, OBJ_TREND, 0, iTime(ativo, periodo, L2), preco1, iTime(ativo, periodo, L1), preco2);
         ObjectSetInteger(0, Rem, OBJPROP_RAY_RIGHT, true);
         //int r = MathRandRange(0, 160);
         //int g = MathRandRange(0, 160);
         //int b = MathRandRange(0, 255);
         //ObjectSetInteger(0, Rem, OBJPROP_COLOR, StringToColor(r + "," + g + "," + 255));
         //int today_time = DayOfWeek(iTime(ativo, periodo, 0));
         //int trend_time = DayOfWeek(iTime(ativo, periodo, L2));
         ObjectSetInteger(0, Rem, OBJPROP_COLOR, UpTrendColorRecent);
         if (L2 > historicBars || L1 > historicBars)
            ObjectSetInteger(0, Rem, OBJPROP_COLOR, UpTrendColorHistoric);
         ObjectSetInteger(0, Rem, OBJPROP_WIDTH, TrendlineWidth);
         ObjectSetInteger(0, Rem, OBJPROP_STYLE, TrendlineStyle);
         //string s = "Dolarizado 1: " + DoubleToString(dolar1 * preco2, 0) +
         //           "\nDolarizado 2: " + DoubleToString(dolar2 * preco2, 0);
         //ObjectSetString(0, Rem, OBJPROP_TOOLTIP, s);
      }

      filterTrend(Rem, historic);
   }

   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool filterTrend(string s, bool historic) {
   double p = ObjectGetValueByTime(0, s, iTime(ativo, PERIOD_CURRENT, 0), 0);
   double fatorLimitador;

   if (historic)
      fatorLimitador = fatorLimitadorHistoric;
   else
      fatorLimitador = fatorLimitadorRecent;

   if (p < precoAtual * (1 - fatorLimitador / 100) || p > precoAtual * (1 + fatorLimitador / 100))
      ObjectDelete(0, s);

   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MathRandRange(double x, double y) {
   return(x + MathMod(MathRand(), MathAbs(x - (y + 1))));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetTD(int P, const double& Arr[]) {
   int i = 0, j = 0;
   while(j < P) {
      i++;
      while(Arr[i] == 0) {
         i++;
         if(i > _showBars - 2)
            return(-1);
      }
      j++;
   }
   return (i);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetNextHighTD(int P, enum_hhll enableTrend) {
   //int i = P + 1;
   //if (!enableHH) {
   //   while(Buf1[i] <= iHigh(ativo, periodo, P)) {
   //      i++;
   //      if(i > _showBars - 2)
   //         return(-1);
   //   }
   //} else {
   //   while(Buf1[i] >= iHigh(ativo, periodo, P)) {
   //      i++;
   //      if(i > _showBars - 2)
   //         return(-1);
   //   }
   //}
   //return (i);

   int i = P + 1;
   if (enableTrend == enableDown) {
      while(Buf1[i] <= iHigh(ativo, periodo, P) || Buf1[i] == 0) {
         i++;
         if(i > _showBars - 2)
            return(-1);
      }
   } else if (enableTrend == enableUp) {
      while(Buf1[i] >= iHigh(ativo, periodo, P) || Buf1[i] == 0) {
         i++;
         if(i > _showBars - 2)
            return(-1);
      }
   } else if (enableTrend == enableAll) {
      while(Buf1[i] == 0) {
         i++;
         if(i > _showBars - 2)
            return(-1);
      }
   }
   return (i);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetNextLowTD(int P, enum_hhll enableTrend) {
   int i = P + 1;
   if (enableTrend == enableUp) {
      while(Buf2[i] >= iLow(ativo, periodo, P) || Buf2[i] == 0) {
         i++;
         if(i > _showBars - 2)
            return(-1);
      }
   } else if (enableTrend == enableDown) {
      while(Buf2[i] <= iLow(ativo, periodo, P) || Buf2[i] == 0) {
         i++;
         if(i > _showBars - 2)
            return(-1);
      }
   } else if (enableTrend == enableAll) {
      while(Buf2[i] == 0) {
         i++;
         if(i > _showBars - 2)
            return(-1);
      }
   }
   return (i);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemHigh(int cnt, int sh) {
   if(iHigh(ativo, periodo, cnt) >= iHigh(ativo, periodo, cnt + sh) && iHigh(ativo, periodo, cnt) > iHigh(ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemHigh(cnt, sh - 1));
      else
         return(iHigh(ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DemLow(int cnt, int sh) {
   if(iLow(ativo, periodo, cnt) <= iLow(ativo, periodo, cnt + sh) && iLow(ativo, periodo, cnt) < iLow(ativo, periodo, cnt - sh)) {
      if(sh > 1)
         return(DemLow(cnt, sh - 1));
      else
         return(iLow(ativo, periodo, cnt));
   } else
      return(0);
}

//+------------------------------------------------------------------+

void OnChartEvent(const int id, const long & lparam, const double & dparam, const string & sparam) {

//if(id == CHARTEVENT_CHART_CHANGE) {
//   _lastOK = true;
//   CheckTimer();
//   return;
//}
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

bool _lastOK = false;
MillisecondTimer *_updateTimer;
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
