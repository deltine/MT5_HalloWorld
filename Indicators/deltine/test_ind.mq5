//+------------------------------------------------------------------+
//|                                                     test_ind.mq5 |
//|                                          Copyright 2024, deltine |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "2024 deltine"  // インジケータを利用する際に表示される
#property link      ""              // インジケータを利用する際に表示される
#property version   "1.00"          // インジケータを利用する際に表示される

#include <MovingAverages.mqh> // 他のファイルの処理が使いたい場合はインクルード必要

#property indicator_chart_window    // チャート上に描画するタイプの指定。オシエータ（MACD等）は記載が異なる
#property indicator_buffers 4       // バッファの本数
#property indicator_plots   4       // 描画するバッファの本数（計算だけして描画しないケースがある）
#property indicator_type1   DRAW_LINE  // 1つ目のバッファのタイプ。今回は移動平均を表示するのでLINE
#property indicator_type2   DRAW_LINE  // 2つ目のバッファのタイプ。今回は移動平均を表示するのでLINE
#property indicator_type3   DRAW_ARROW // 3つ目のバッファのタイプ。ゴールデンクロスした箇所を矢印で表示
#property indicator_type4   DRAW_ARROW // 4つ目のバッファのタイプ。デッドクロスした箇所を矢印で表示

input int            InpMAPeriod1 = 20;   // 短期移動平均（短期MA）の期間数
input color          InpColor1 = clrRed;  // 短期MAの色
input int            InpMAPeriod2 = 200;  // 長期移動平均（長期MA）の期間数
input color          InpColor2 = clrBlue; // 長期MAの色

double gMovingAverage1Buffer[];  // 短期MAのバッファ
double gMovingAverage2Buffer[];  // 長期MAのバッファ
double gSignalGoldenCross[];     // ゴールデンクロスのバッファ
double gSignalDeadCross[];       // デッドクロスのバッファ

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- インジケータの名前
   IndicatorSetString(INDICATOR_SHORTNAME,
                      "MA(" +
                      string(InpMAPeriod1) +
                      ", " +
                      string(InpMAPeriod2) +")");
//--- バッファの名前
   PlotIndexSetString(0, PLOT_LABEL, "MA(" + string(InpMAPeriod1) + ")");
   PlotIndexSetString(1, PLOT_LABEL, "MA(" + string(InpMAPeriod2) + ")");
   PlotIndexSetString(2, PLOT_LABEL, "GoldenCross");
   PlotIndexSetString(3, PLOT_LABEL, "DeadCross");
//--- バッファのマッピング。第一引数が大事。0始まり。
   SetIndexBuffer(0, gMovingAverage1Buffer, INDICATOR_DATA);
   SetIndexBuffer(1, gMovingAverage2Buffer, INDICATOR_DATA);
   SetIndexBuffer(2, gSignalGoldenCross, INDICATOR_DATA);
   SetIndexBuffer(3, gSignalDeadCross, INDICATOR_DATA);
//---- バッファの初期値を0へ
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
//--- バッファの色
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, InpColor1);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, InpColor2);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrYellow);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrGreen);
//--- 線や破線等を設定可能
   PlotIndexSetInteger(0, PLOT_LINE_STYLE, STYLE_DOT);
   PlotIndexSetInteger(1, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(2, PLOT_ARROW, 233); // 上矢印
   PlotIndexSetInteger(3, PLOT_ARROW, 234); // 下矢印
//--- バッファの有効桁数
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits + 1);

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//|  Custom indicator  deinitialization function                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // インジケータを使わなくなった際の処理
   // メモリ解放
   ArrayFree(gMovingAverage1Buffer);
   ArrayFree(gMovingAverage2Buffer);
   ArrayFree(gSignalGoldenCross);
   ArrayFree(gSignalDeadCross);
  }
//+------------------------------------------------------------------+
//|  Moving Average                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   // メイン処理
   // 価格の変動時に動作
   static int i = InpMAPeriod2;  // 始点のインデックスを設定。MAを算出するので0だと算出できない

   for(; i < rates_total; i++)
     {
      // SimpleMAメソッドはMAを算出してくれる。バッファに単純移送。
      gMovingAverage1Buffer[i] = SimpleMA(i, InpMAPeriod1, price);
      gMovingAverage2Buffer[i] = SimpleMA(i, InpMAPeriod2, price);

      // ゴールデンクロスの判定
      // [i - 1]はひとつ前のローソク足。なので、ひとつ前と現在のローソク足の状態でシグナルを判定している
      if(gMovingAverage1Buffer[i - 1] < gMovingAverage2Buffer[i - 1]
         && gMovingAverage1Buffer[i] > gMovingAverage2Buffer[i])
        {
         gSignalGoldenCross[i] = price[i]; // 現在値を設定し、現在地付近に矢印を表示させる
        }

      // デッドクロスの判定
      // 同上。ゴールデンクロスと逆の条件になる
      if(gMovingAverage1Buffer[i - 1] > gMovingAverage2Buffer[i - 1]
         && gMovingAverage1Buffer[i] < gMovingAverage2Buffer[i])
        {
         gSignalDeadCross[i] = price[i]; // 現在値を設定、現在地付近に矢印を表示させる
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
