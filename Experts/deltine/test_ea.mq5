//+------------------------------------------------------------------+
//|                                                      test_ea.mq5 |
//|                                          Copyright 2024, deltine |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "2024 deltine"  // インジケータを利用する際に表示される
#property link      ""              // インジケータを利用する際に表示される
#property version   "1.00"          // インジケータを利用する際に表示される

#include <Trade\Trade.mqh>          // 他のファイルの処理が使いたい場合はインクルード必要
#include <Trade\SymbolInfo.mqh>     // インジケータは不用。iCustomメソッドで読込
#include <Trade\PositionInfo.mqh>   // ポジションは売買した情報等のこと
#include <Trade\AccountInfo.mqh>    // アカウント（口座）の情報等のこと

#define MAGIC_NO 202402 // EAを識別するID。EAを複数稼働させるときなどに利用する。

//--- input parameters
input double   InpLots          =0.1;  // EAの引数。今回はロット（購入する量）を設定

CTrade            m_trade; // 必要なクラスを定義
CSymbolInfo       m_symbol;
CPositionInfo     m_position;
CAccountInfo      m_account;

int gHandle;   // test_ind用のハンドル。ハンドルをキーにバッファを取得する為。

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
void OnInit()
  {
   // 初期化処理
   // インジケータの読込
   gHandle = iCustom(_Symbol, _Period, "deltine/test_ind");

   // その他（割愛）
   m_symbol.Name(Symbol());
   m_trade.SetExpertMagicNumber(MAGIC_NO);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(Symbol());

   return;
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // EAを使わなくなった際の処理
   // ハンドルからインジケータのメモリを解放
   if(gHandle != INVALID_HANDLE)
      IndicatorRelease(gHandle);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   // メイン処理
   // 価格の変動時に動作
   static int barCnt = Bars(_Symbol, _Period);

   // 価格の変動時に変わるスプレッド等の値を毎回エイフレッシュする必要がある
   if(!m_symbol.RefreshRates())
      return;

   if(barCnt != Bars(_Symbol, _Period)    // 新しいローソク足が発生した時だけトレードを行う
      && m_symbol.Spread() < 10           // スプレッド（手数料）が少ない時だけトレードを行う
     )
     {
      if(PositionsTotal() == 0)  // ポジションの総数を確認※全部のEAのトータル。今回はマジックナンバーは確認はスキップ
        {
         // 何もオープン（売買していない）時だけ、取引する

         double signalGoldenCross[];
         CopyBuffer(gHandle, 3, 0, 2, signalGoldenCross);   // 直近のゴールデンクロスシグナルを取得
         
         // CopyBuffer(gHandle, 3, 0, [2]←2つ値を取っている理由は、ひとつ前のローソク足のゴールデンクロスの「確定」を待つ為

         if(signalGoldenCross[0] > 0)  // [0]はひとつ前のローソク足
           {
            LongOpen(); // Long(買い注文)をOpen（出す。開始する。）
                        // ちなみに、LongCloseはLong(買い注文)をClose（終える。手じまい。）
            return;
           }

         double signalDeadCross[];
         CopyBuffer(gHandle, 4, 0, 2, signalDeadCross);  // 直近のデッドクロスシグナルを取得

         if(signalDeadCross[0] > 0)
           {
            ShortOpen(); // Short(売り注文)をOpen（出す。開始する。）
            return;
           }
        }
     }
   return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LongOpen(void)
  {
   double price=m_symbol.Ask();
   double sl   =m_symbol.Bid()-100*_Point;
   double tp   =m_symbol.Bid()+100*_Point;
//--- check for free money
   double FreeMargin = m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_BUY,InpLots,price);
   if(FreeMargin<0.0)
     {
      Print("price ", price, " tp ", tp, " FreeMargin ", FreeMargin);
      printf("We have no money. Free Margin = %f",m_account.FreeMargin());
     }

   else
     {
      //--- open position
      if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_BUY,InpLots,price,sl,tp))
         printf("Position by %s to be opened",Symbol());
      else
        {
         printf("Error opening BUY position by %s : '%s'",Symbol(),m_trade.ResultComment());
         printf("Open parameters : price=%f,TP=%f",price,tp);
        }
     }
//--- in any case we must exit from expert
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ShortOpen(void)
  {
   double price=m_symbol.Bid();
   double sl   =m_symbol.Ask()+100*_Point;
   double tp   =m_symbol.Ask()-100*_Point;
//--- check for free money
   double FreeMargin = m_account.FreeMarginCheck(Symbol(),ORDER_TYPE_SELL,InpLots,price);
   if(FreeMargin<0.0)
     {
      Print("price ", price, " tp ", tp, " FreeMargin ", FreeMargin);
      printf("We have no money. Free Margin = %f",m_account.FreeMargin());
     }

   else
     {
      //--- open position
      if(m_trade.PositionOpen(Symbol(),ORDER_TYPE_SELL,InpLots,price,sl,tp))
         printf("Position by %s to be opened",Symbol());
      else
        {
         printf("Error opening SELL position by %s : '%s'",Symbol(),m_trade.ResultComment());
         printf("Open parameters : price=%f,TP=%f",price,tp);
        }
     }
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LongClose(void)
  {
   if(m_trade.PositionClose(Symbol()))
      printf("Long position by %s to be closed",Symbol());
   else
      printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ShortClose(void)
  {
   if(m_trade.PositionClose(Symbol()))
      printf("Short position by %s to be closed",Symbol());
   else
      printf("Error closing position by %s : '%s'",Symbol(),m_trade.ResultComment());
   return(true);
  }
//+------------------------------------------------------------------+
