//+---------------------------------------------------------------------------------+
//|                                           MA RSI.mq4                            |
//|                                  Copyright 2013, Alex Hutchinson                |
//|                                  http://www.alexhutchinson.info                 |
//|                                  version 1.7.1                                    |
//| positive pairs: M5  MA: 50/200  5m EURJPY/!GBPUSD (opt: 1000SL MA1=65 MA2 290 RSIEXIT=34) /USDCHF/!CHFJPY/!USDJPY (opt: 45/160 RSIExit=29)           |
//|                
//|                 H1  MA: 50/200 SL 400 EURUSD(+MA CROSS OVER CHECK ON CLOSE)/USDCHF/AUDUSD/AUDNZD/EURGBP(50/200) |!CADJPY (65/290)
//|
//|                 improved with above/below MA2 check on open:- M5 = GBPUSD EURAUD 
//| Spread effect : 0.1 pip change results in approc £35-50 per year (based on around 100 trades a month)
//| poaitive on ranging : USDJPY (RSI14 SL420 MA45/160) / CHFJPY (RSI14 SL420 MA45/160)/ !GBPJPY (RSI14 SL420 MA65/290) / NZDJPY / EURJPY  (RSI14 SL420 MA65/290)                            
//+---------------------------------------------------------------------------------+
#property copyright "Copyright 2014, Alex Hutchinson. v1.7.3"
#property link      "http://www.alexhutchinson.info"

#define MAGICMA  20141114

double MA1;
double MALong1;
double MA2;
double MALong2;
double MA2Compare;
double pips;
double RSI;
double RSIPreviousBar1;
double RSIPreviousBar2;
double RSIExit;
double RSIRanging;
double Spread[];  
double SpreadPips;
int    SpreadMultiplier;
int   RSIExitHit;
// variables for IsRanging method
bool   ranging;
int    objectId;
double MAvariance;
// variables for Stopped out method
bool hasPaused = false;
bool tradingPaused;
 uint startTickCount;
 bool tickCountStarted;


// external variables =============================
extern double Lots = 0.05;
extern double Ea_StopLoss = 1000;
extern double Ea_TakeProfit = 400;
extern double MA_1 = 50;
extern double MA_2 = 200;
extern int RSI_Period_Entry = 14;
extern int RSI_Period_Exit = 24;
extern int RSI_Period_Ranging = 14;
extern int Slippage = 3;
extern int SpreadSampleSize = 100000;
extern int maxSpread = 20;
extern bool Ranging = true;
extern int Wait_Time = 60;
extern bool price_AboveBelow_MA2 = True;
extern int Check_if_rsi_was_hit_periods = 6;
extern int Pause_before_another_trade = 3600;

//==================================================

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//----

// -------------------------------------------

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
//----
//if(IsVisualMode()==true){ IsTestingDelay(1); }


SpreadPips =  NormalizeDouble(MarketInfo(Symbol(),MODE_SPREAD),2)/10;


if (Symbol() == "USDJPY"){SpreadMultiplier = 100;}
else{ SpreadMultiplier = 10000; }
 

MA1 = iMA(Symbol(),Period(),MA_1,1,MODE_SMA,PRICE_CLOSE,1);
MA2 = iMA(Symbol(),Period(),MA_2,1,MODE_SMA,PRICE_CLOSE,1);
MALong1 = iMA(Symbol(),60,8,1,MODE_EMA,PRICE_CLOSE,1);
MALong2 = iMA(Symbol(),60,34,1,MODE_EMA,PRICE_CLOSE,1);
MA2Compare = iMA(Symbol(),Period(),MA_2,0,MODE_SMA,PRICE_CLOSE,14);
RSI = iRSI(Symbol(),Period(),RSI_Period_Entry,PRICE_CLOSE,0);
RSIPreviousBar1 = iRSI(Symbol(),Period(),RSI_Period_Entry,PRICE_CLOSE,1);
RSIPreviousBar2 = iRSI(Symbol(),Period(),RSI_Period_Entry,PRICE_CLOSE,2);
RSIExit = iRSI(Symbol(),Period(),RSI_Period_Exit,PRICE_CLOSE,0);
RSIRanging = iRSI(Symbol(),Period(),RSI_Period_Ranging,PRICE_CLOSE,0);


bool Ea_TradeOpen = false;
bool isBuyTrade = false;
bool isSellTrade = false;
bool RecentBuy = false;
bool RecentSell = false;
int maxBuyTrades = 20;
int buyTrades = 0;
int maxSellTrades = 20;
int sellTrades = 0;
int Ea_Ticket_Nbr = 0;
int total=OrdersTotal();


double Ea_Open_StopLoss = 0;

  if (total > 0)
  {
  for(int p=0;p<total;p++)
    {
    // detects if the EA already has a trade(s) in progress-----------------------------------------------------------------------
     if(OrderSelect(p,SELECT_BY_POS)==false) continue;
       if((OrderMagicNumber() == MAGICMA) && (OrderSymbol() == Symbol())) 
         {
            Ea_TradeOpen = true;
            
            
            if (OrderType() == 0) // the trade selected is a BUY trade 
            {
               isBuyTrade = true;
               buyTrades ++;
               if (TimeHour(OrderOpenTime()) == TimeHour(TimeCurrent()) && TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent()) )// |  TimeCurrent()-OrderOpenTime() < Pause_before_another_trade
               {
                  RecentBuy = true;
               }
               else
               {
                  RecentBuy = false;
               }
            }
            else if (OrderType() == 1)// the trade selected is a SELL trade 
            {
               isSellTrade = true;
               sellTrades ++;
               if (TimeHour(OrderOpenTime()) == TimeHour(TimeCurrent()) && TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent()))
               {
                  RecentSell = true;
               }
               else
               {
                  RecentSell = false;
               }
            }
         }
    }
    }

// Start pause timer if stop loss was hit (removed at v1.5 as not profitable)================================================================================

//if(LastTradeStoppedOut() && !hasPaused)
//{
//        if(!tickCountStarted)
//        {
//           tickCountStarted = true;
//           startTickCount = GetTickCount();
//           tradingPaused = true;
//        }
//        else
//        {
//           if(GetTickCount()< (startTickCount + (Wait_Time * 10)))
//           {
//               tradingPaused = true;
//           }
//           else
//           {
//               tradingPaused = false;
//               hasPaused = true;
//               tickCountStarted = false;
//           }
//        }
//}
// EA Checks if there are open trades================================================================================

    
if ( true  )//&& !tradingPaused if no open positions - check for possible trade=======================
  {
  // Buy Trade setup??------------------------------------------------------------------------------------------------------------------------------
  if(  (buyTrades <= maxBuyTrades) && !RecentBuy  && !IsRanging(MA2, MA2Compare))// if market is trending...
  {
      if ( MA1 > MA2 && RSILowWasHit(Check_if_rsi_was_hit_periods) && SpreadPips <= maxSpread && MALong1 > MALong2  )// && RSIPreviousBar1 > RSIPreviousBar2
      {
         if(price_AboveBelow_MA2)
         {
            if(DayOfWeek() != 0 && Ask > MA2) 
            {
               int ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"MA RSI ("+DoubleToStr((Ask-Bid)*SpreadMultiplier,2)+")",MAGICMA,0,Green);
               if (ticket > 0)
               {
                  Print("Order placed # ", ticket);
                  isBuyTrade = true;
               }
               else
               {
                  Print("Order failed : ", GetLastError());
               }
               
            }
         }
         else
         {
            if(DayOfWeek() != 0) 
            {
               int ticket2 = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"MA RSI ("+DoubleToStr((Ask-Bid)*SpreadMultiplier,2)+")",MAGICMA,0,Green);
               if (ticket2 > 0)
               {
                  Print("Order placed # ", ticket2);
                  isBuyTrade = true;
               }
               else
               {
                  Print("Order failed : ", GetLastError());
               }
               
            }
         }
      }
  }
  else // Else If market is ranging....
  {
      if ( (buyTrades <= maxBuyTrades) && !RecentBuy  && IsRanging(MA2, MA2Compare) && RSIRanging < 30 && SpreadPips <= maxSpread    )//&& RSIPreviousBar1 > RSIPreviousBar2
      {
         if(DayOfWeek() != 0) 
         {
            int ticket3 = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"MA RSI ("+DoubleToStr((Ask-Bid)*SpreadMultiplier,2)+")",MAGICMA,0,Green);
             if (ticket3 > 0)
            {
               Print("Order placed # ", ticket3);
               isBuyTrade = true;
            }
            else
            {
               Print("Order failed : ", GetLastError());
            }
         }
      }
  }
  
  
  // Sell trade set up ?? -----------------------------------------------------------------------------------------------------------------------------
    if( (sellTrades <= maxSellTrades) && !RecentSell  && !IsRanging(MA2, MA2Compare)) // If market is trending......
    {
      if (  MA1 < MA2 && RSIHighWasHit(Check_if_rsi_was_hit_periods) && SpreadPips <= maxSpread && MALong1 < MALong2  )//&& RSIPreviousBar1 > RSIPreviousBar2
      {
         if(price_AboveBelow_MA2)
         {
            if(DayOfWeek() != 0  && Bid < MA2) 
            {
               int ticket4 = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"MA RSI ("+DoubleToStr((Ask-Bid)*SpreadMultiplier,2)+")",MAGICMA,0,Red); 
               if (ticket4 > 0)
               {
                  Print("Order placed # ", ticket4);
                  isSellTrade = true;
               }
               else
               {
                 Print("Order failed : ", GetLastError());
               }
            }
         }
         else
         {
            if(DayOfWeek() != 0) 
            {
               int ticket5 = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"MA RSI ("+DoubleToStr((Ask-Bid)*SpreadMultiplier,2)+")",MAGICMA,0,Red); 
               if (ticket5 > 0)
               {
                  Print("Order placed # ", ticket5);
                  isSellTrade = true;
               }
               else
               {
                 Print("Order failed : ", GetLastError());
               }
            }
         }
      }
    }
    else // Else If market is ranging....
    {
      if ((sellTrades <= maxSellTrades) && !RecentSell  && IsRanging(MA2, MA2Compare) && RSIRanging > 70 && SpreadPips <= maxSpread   )//&& RSIPreviousBar1 < RSIPreviousBar2
      {
            if(DayOfWeek() != 0) 
            {
               int ticket6  = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"MA RSI ("+DoubleToStr((Ask-Bid)*SpreadMultiplier,2)+")",MAGICMA,0,Red); 
               if (ticket6 > 0)
               {
                  Print("Order placed # ", ticket6);
                  isSellTrade = true;
               }
               else
               {
                  Print("Order failed : ", GetLastError());
               }
            }
      }
    }
  
  }
  if (total > 0)
  {
  for(int pos=0;pos<total;pos++)
    {
    // detects if the EA already has a trade(s) in progress-----------------------------------------------------------------------
     if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
       if((OrderMagicNumber() == MAGICMA) && (OrderSymbol() == Symbol())) 
         {
            Ea_TradeOpen = true;
            Ea_Ticket_Nbr = OrderTicket();
            Ea_Open_StopLoss = OrderStopLoss();
            
            if (OrderType() == 0) // the trade selected is a BUY trade =  Check for close conditions--------------------------------
            {
                  isBuyTrade = true;
                  
                 if (OrderSelect(Ea_Ticket_Nbr,SELECT_BY_TICKET))
                  {// select the order
                    if(OrderStopLoss()==0){bool success =  OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()-Ea_StopLoss*Point,OrderOpenPrice()+Ea_TakeProfit*Point,0,Blue);return(0);}
                  //  else if (RSI > 70 ){OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),0,0,Blue);return(0);}
                   
                    pips = OrderOpenPrice() - Bid;
                    if(!IsRanging(MA2, MA2Compare))
                    {
                        if(  RSIExit > 70 )//
                        {
                          bool closedrsi = OrderClose(OrderTicket(),OrderLots(),Bid, Slippage, Blue);
                          if (closedrsi){ isBuyTrade = false; RSIExitHit++;}
                        }
                        else if(MA1 < MA2)
                        {
                          bool closed = OrderClose(OrderTicket(),OrderLots(),Bid, Slippage, Blue);
                          if (closed){ isBuyTrade = false; }
                        }
                     }
                     else
                     {
                        if(  RSIRanging > 70 )
                        {
                          bool closed2 = OrderClose(OrderTicket(),OrderLots(),Bid, Slippage, Blue);
                          if (closed2){ isBuyTrade = false;}
                        }
                     }
                    // else if (DayOfWeek() == 6)
                    // {
                    //    OrderClose(OrderTicket(),OrderLots(),Bid, Slippage, Blue);
                    // }
                  }
                  
            }
            if (OrderType() == 1) // the trade selected is a SELL trade =  Check for close conditions--------------------------------
            {
                  isSellTrade = true;
            
                 if(OrderSelect(Ea_Ticket_Nbr,SELECT_BY_TICKET))
                    {// select the order
                    if(OrderStopLoss()==0){OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice()+Ea_StopLoss*Point,OrderOpenPrice()-Ea_TakeProfit*Point,0,Blue);return(0);}
                   // else if (RSI < 30 ){OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),0,0,Blue);return(0);}
                    
                     pips = OrderOpenPrice() + Ask;
                    if(!IsRanging(MA2, MA2Compare))
                    {
                        if(  RSIExit < 30 )
                        {
                           bool closedrsi2 =  OrderClose(OrderTicket(),OrderLots(),Ask, Slippage, Blue);
                           if (closedrsi2){ isSellTrade = false;RSIExitHit++;}
                        }
                        else if(MA1 > MA2)
                        {
                           bool closed3 =  OrderClose(OrderTicket(),OrderLots(),Ask, Slippage, Blue);
                           if (closed3){ isSellTrade = false; }
                        }
                    }
                    else
                    {
                        if(  RSIRanging < 30 )
                        {
                           bool closed4 =  OrderClose(OrderTicket(),OrderLots(),Ask, Slippage, Blue);
                           if (closed4){ isSellTrade = false;}
                        }
                    }
                  //   else if (DayOfWeek() == 6)
                  //   {
                  //      OrderClose(OrderTicket(),OrderLots(),Bid, Slippage, Blue);
                  //   }
                     }
            }
         }
      }
    } 
  
  
// Comment section==================================================================================================================
Comment(

  "pips : " + pips + "\n",
  "average spread : " + Spread()*SpreadMultiplier +"\n",
  "current sread :  " + SpreadPips + "\n",
  "RSI 14 : " + RSI+ "\n",
  "Ranging? : " +  ranging +"\n",
  "MA Variance : " + MAvariance+"\n",
  "paused? : " + tradingPaused+ "  " + LastTradeStoppedOut() + " \n",
  "Number of RSI exits : "+RSIExitHit
  );
//----

   return(0);
  }

//HELPER FUNCTIONS--------------------------------------------------------------------------------------------------------------------------
//+----------------------------------------------------------------+
//| RSILowWasHit  - Checks if RSI low(30) was hit during x periods |
//+----------------------------------------------------------------+
bool RSILowWasHit(int periods=0)
   {
      bool hit = false;
      for(int i=0;i<periods;i++)
        {
            int RSIlow = iRSI(Symbol(),Period(),RSI_Period_Entry,PRICE_CLOSE,i);
            if (RSIlow <30){ hit = true;}
        }
        return hit;
   }  // end of RSILowWasHit
//+--------------------------------------------------------+
  
//+--------------------------------------------------------+
//+------------------------------------------------------------------+
//| RSIHighWasHit  - Checks if RSI high(70) was hit during x periods |
//+------------------------------------------------------------------+
bool RSIHighWasHit(int periods=0)
   {
      bool hit = false;
      for(int i=0;i<periods;i++)
        {
            int RSIhigh = iRSI(Symbol(),Period(),RSI_Period_Entry,PRICE_CLOSE,i);
            if (RSIhigh > 70){ hit = true;}
        }
        return hit;
   }  // end of RSILowWasHit
//+--------------------------------------------------------+
  
//+--------------------------------------------------------+
//+-----------------------------------------------------+
//| Spread function - used to calculate SMA of Spread   |
//+-----------------------------------------------------+
double Spread(double AddValue=0)
   {
   double LastValue;
   static double ArrayTotal=0;
   
   if (AddValue == 0 && SpreadSampleSize <= 0) return(Ask-Bid);
   if (AddValue == 0 && ArrayTotal == 0) return(Ask-Bid);
   if (AddValue == 0 ) return(ArrayTotal/ArraySize(Spread));
   
   ArrayTotal = ArrayTotal + AddValue;
   ArraySetAsSeries(Spread, true); 
   if (ArraySize(Spread) == SpreadSampleSize)
      {
      LastValue = Spread[0];
      ArrayTotal = ArrayTotal - LastValue;
      ArraySetAsSeries(Spread, false);
      ArrayResize(Spread, ArraySize(Spread)-1 );
      ArraySetAsSeries(Spread, true);
      ArrayResize(Spread, ArraySize(Spread)+1 ); 
      }
   else ArrayResize(Spread, ArraySize(Spread)+1 ); 
//   Print("ArraySize = ",ArraySize(lSpread)," AddedNo. = ",AddValue);
   ArraySetAsSeries(Spread, false);
   Spread[0] = AddValue;
   return(NormalizeDouble(ArrayTotal/ArraySize(Spread), Digits));
   }  // end of Spread
//+--------------------------------------------------------+
  
//+------------------------------------------------------------------+
//+-------------------------------------------------------------------+
//| IsRanging function - used to determine if the market is ranging   |
//+-------------------------------------------------------------------+
bool IsRanging(double MA, double MACompare)
   {
     if(Ranging)
     { 
      MAvariance = MA - MACompare;
      Print(DoubleToStr(MAvariance,2));
      if((TimeHour(TimeCurrent()) >= 0 && TimeHour(TimeCurrent()) <= 6)|| (MAvariance <= 0.0001 && MAvariance >= -0.0001 ))
      {
         if(ranging == false)
         {
            objectId ++;
            ObjectCreate("ranging",OBJ_VLINE,0,TimeCurrent(),0);
            ObjectSet("ranging", OBJPROP_COLOR, Green);
            
            ranging = true;
            return (true);
         }
         else
         {
            ranging = true;
            return (true);
         }      
      }
      else
      {
         if(ranging == true)
         {
            objectId = 123;
            ObjectCreate("not ranging",OBJ_VLINE,0,TimeCurrent(),0);
            
            ranging = false;
            return (false);
         }
         else
         {
            ranging = false;
            return (false);
         }      
      }
      }
      else{return (false);}
   }  // end of IsRanging
//+--------------------------------------------------------+
  
//+------------------------------------------------------------------+
//+-------------------------------------------------------------------+
//| LastTradeStoppedOut function - tells if the last trade hit StopLoss  |
//+-------------------------------------------------------------------+
bool LastTradeStoppedOut()
   { 
      bool result = false;
  
      for(int i=OrdersHistoryTotal();i>=0;i--)
      {
         OrderSelect(i, SELECT_BY_POS,MODE_HISTORY);
         if(OrderSymbol()==Symbol() && OrderMagicNumber()== MAGICMA )
         {
             if( NormalizeDouble(OrderClosePrice(),4)== NormalizeDouble(OrderStopLoss(),4)) 
             { 
               result = true;
               return (result);
               
             }
             else
             {
               result = false;
               hasPaused = false;
               return (result);
               
             }  
         }
         
      }
   }  // end of LastTradeStoppedOut
//+--------------------------------------------------------+
  
//+------------------------------------------------------------------+