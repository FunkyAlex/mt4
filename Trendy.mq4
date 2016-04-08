//+---------------------------------------------------------------------------------+
//|                                           Trendy.mq4                            |
//|                                  Copyright 2014, Alex Hutchinson                |
//|                                  http://www.alexhutchinson.info                 |
//|                                  version 1.0.0                                  |
//|  
//|              M15 GBPUSD EURUSD SLTP 600/900  
//|              H1  GBPUSD        SLTP 400/2000   
//|
//|                  
//| 
//|                             
//+---------------------------------------------------------------------------------+
#property copyright "Copyright 2014, Alex Hutchinson. v1.0.0"
#property link      "http://www.alexhutchinson.info"

#define MAGICMA  3

double pips;
double ATR;
double MACD_0;
double MACD_1;
double MACD_2;
double MACD_3;
double MACD_4;
double MACD_5;
double High_1;
double Low_1;
bool m_bNewBar    = false;
int m_nLastBars   = 0;
int ThisBarTrade  =  0;


// external variables =============================

extern double Lots = 0.05;
extern int Slippage = 3;
extern double Ea_StopLoss = 500;
extern double Ea_TakeProfit = 100000;
extern double MacdLimit = 0.0001;

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
void start()
  {
//----
//if(IsVisualMode()==true){ IsTestingDelay(1); }

if (Bars != ThisBarTrade ) {
   ThisBarTrade = Bars;  // ensure only one trade opportunity per bar

bool Ea_TradeOpen = false;
bool isTrade = false;
bool isSellTrade = false;
bool RecentBuy = false;
bool RecentSell = false;
int maxBuyTrades = 20;
int buyTrades = 0;
int maxSellTrades = 20;
int sellTrades = 0;
int Ea_Ticket_Nbr = 0;
int total=OrdersTotal();

MACD_0 = iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,MODE_MAIN,0);
MACD_1 = iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,MODE_MAIN,1);
MACD_2 = iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,MODE_MAIN,2);
MACD_3 = iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,MODE_MAIN,3);
MACD_4 = iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,MODE_MAIN,4);
MACD_5 = iMACD(Symbol(),Period(),12,26,9,PRICE_CLOSE,MODE_MAIN,5);

High_1 = iHigh(Symbol(),Period(),1);
Low_1 = iLow(Symbol(),Period(),1);

  if (total > 0)
  {
  for(int p=0;p<total;p++)
    {
    // detects if the EA already has a trade(s) in progress-----------------------------------------------------------------------
     if(OrderSelect(p,SELECT_BY_POS)==false) continue;
       if((OrderMagicNumber() == MAGICMA) && (OrderSymbol() == Symbol())) 
         {
            isTrade = true;
            

            
            if (OrderType() == 0) // the trade selected is a BUY trade 
            {
        
               buyTrades ++;
               if (TimeHour(OrderOpenTime()) == TimeHour(TimeCurrent()) && TimeDayOfYear(OrderOpenTime()) == TimeDayOfYear(TimeCurrent()) )// |  TimeCurrent()-OrderOpenTime() < Pause_before_another_trade
               {
                  RecentBuy = true;
               }
               else
               {
                  RecentBuy = false;
                  
               }
               
            //    if(MACD_1 < MACD_2 && MACD_2 < MACD_3 && MACD_3 < MACD_4)
            //   {
            //      OrderClose(OrderTicket(),OrderLots(),Bid, NULL);
            //   }
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
               
             //  if(MACD_1 > MACD_2 && MACD_2 > MACD_3 && MACD_3 < MACD_4)
             //  {
             //     OrderClose(OrderTicket(),OrderLots(),Ask, NULL);
             //  }
            }
         }
    }
    }

  // Buy Trade setup??------------------------------------------------------------------------------------------------------------------------------

 
  if(DayOfWeek() != 0 && !isTrade && MACD_1 > MACD_2 && MACD_2 < MACD_3 && MACD_3 < MACD_4 && MACD_0 > 0 && MACD_1 > (0+MacdLimit))//
  {
      
               int ticket = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask -Ea_StopLoss*Point,Ask+Ea_TakeProfit*Point,"Trendy",MAGICMA,0,Green);
               if (ticket > 0)
               {
                  Print("Order placed # ", ticket);
                  
                  isTrade = true;
               }
               else
               {
                  Print("Order failed : ", GetLastError());
               }
               
  }
  
  // Sell trade set up ?? -----------------------------------------------------------------------------------------------------------------------------
     if(DayOfWeek() != 0 && !isTrade && MACD_1 < MACD_2 && MACD_2 > MACD_3 && MACD_3 > MACD_4 && MACD_0 < 0 && MACD_1 < (0-MacdLimit))//
      {
      
               int ticket2 = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid + Ea_StopLoss*Point,Bid-Ea_TakeProfit*Point,"Trendy",MAGICMA,0,Red);
               if (ticket2 > 0)
               {
                  Print("Order placed # ", ticket2);
                  
                  isTrade = true;
               }
               else
               {
                  Print("Order failed : ", GetLastError());
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
            isTrade = true;
            Ea_Ticket_Nbr = OrderTicket();
            if (OrderType() == 0) // the trade selected is a BUY trade =  Check for close conditions--------------------------------
            {
               if ( TimeCurrent() > OrderOpenTime() + Period()*1)
               {
                  //OrderClose(OrderTicket(),OrderLots(),Bid, Slippage, Blue);
                  isTrade = false;
                  
               } 
            }
            else // the trade selected is a SELL trade =  Check for close conditions--------------------------------
            {
               if ( TimeCurrent() > OrderOpenTime() + Period()*1)
               {
                  //OrderClose(OrderTicket(),OrderLots(),Ask, Slippage, Blue);
                  isTrade = false;
               } 
            }
            
         }
      }
    
  }
  
  
// Comment section==================================================================================================================
Comment(

  ""  + "\n",
  ""
  );
//----

   
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
            int RSIlow = iRSI(Symbol(),Period(),14,PRICE_CLOSE,i);
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
            int RSIhigh = iRSI(Symbol(),Period(),14,PRICE_CLOSE,i);
            if (RSIhigh > 70){ hit = true;}
        }
        return hit;
   }  // end of RSILowWasHit
//+--------------------------------------------------------+
  
//+--------------------------------------------------------+