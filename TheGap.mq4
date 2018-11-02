//+---------------------------------------------------------------------------------+
//|                                  TheGap.mq4                              |
//|                                  Copyright 2018, Alex Hutchinson                |
//|                                  http://www.alexhutchinson.info                 |
//|                                  version 1.0                                    |
//| positive pairs:                                                                 |
//|                                                                                 | 
//|                                                                                 |
//+---------------------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern double TPExtra = 0.7;
extern double SLClip = 0.7;

#define MAGICMA 3
#define MAGICMA2 4

double closeLast;
bool Ea_TradeOpen;
bool insideBarFlag = false;
double outsideHigh;
double outsideLow;
double minimumEntryPips;
double spread;
double high1;
double low1 ;
double high2;
double low2 ;

double EMA8;
double EMA21;

double close1;
double open0;


bool fakeoutLow;
bool fakeoutHigh;
int count;


// external variables =============================
extern int Slippage = 3;
//==================================================

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
  fakeoutLow =false;
fakeoutHigh =false;
count=0;
insideBarFlag = false;
Ea_TradeOpen = false;
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

double Lots = AccountBalance()/10000;

high1 = iHigh(Symbol(), Period(),1);
low1 = iLow(Symbol(), Period(),1);

high2 = iHigh(Symbol(), Period(),2);
low2 = iLow(Symbol(), Period(),2);

close1 = iClose(Symbol(), Period(),1);
open0 = iOpen(Symbol(), Period(),0);

EMA8 = iMA(Symbol(),PERIOD_H1,8,1,MODE_EMA,PRICE_CLOSE,1);
EMA21 = iMA(Symbol(),PERIOD_H1,21,1,MODE_EMA,PRICE_CLOSE,1);


minimumEntryPips = MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point) *3;
spread = MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point);


bool Ea_ReverseTradeOpen = false;
bool Ea_Sell_On = false;
bool Ea_Buy_On = false;

int Ea_Ticket_Nbr = 0;
int total=OrdersTotal();

double Ea_Open_StopLoss = 0;


total = OrdersTotal();
if (total > 0)
  {
  for(int pos=0;pos<total;pos++)
    {
    // detects if the robot already has a trade(s) in progress
     if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
       if((OrderMagicNumber() == MAGICMA) && (OrderSymbol() == Symbol())) 
         {
            Ea_TradeOpen=true;
            /*
            if(OrderType() == 0) //buy - remove stop to breakeven
            {
               string result1[]; 
               StringSplit(OrderComment(),',',result1);
               double outsideLowInOrder = StrToDouble(result1[1]);
               if(Bid >= outsideLowInOrder) 
               { 
                  bool res1 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0, Blue);
                  if(!res1) Print("Error in OrderModify. Error code=",GetLastError());
                  else Print("Order modified successfully.");
                  
               }
                           
            }
            if(OrderType() == 1) //sell - move stop to breakeven
            {
               string result2[]; 
               StringSplit(OrderComment(),',',result2);
               double outsideHighInOrder = StrToDouble(result2[1]) ;
               if(Ask >= outsideHighInOrder) 
               { 
                  bool res2 = OrderModify(OrderTicket(),OrderOpenPrice(),OrderOpenPrice(),OrderTakeProfit(),0,Blue);
                  if(!res2) Print("Error in OrderModify. Error code=",GetLastError());
                  else Print("Order modified successfully.");
               }
            
            }*/
 
        } 
        if((OrderMagicNumber()==MAGICMA2) && (OrderSymbol()==Symbol()))
        {
             Ea_ReverseTradeOpen=true;
        } 
      }
    } 
if (DayOfWeek() == 2)
{
   Ea_TradeOpen  = false;
}

if (Ea_TradeOpen == false)// if no open positions - check for possible trade-------------------------------------
  {
 
     // Buy //
     if (  close1 > (open0 ) && DayOfWeek() == 1 )//  
     {
        double stopLossPipsBuy = (MathAbs(NormalizeDouble(close1 - open0 ,Digits)))* SLClip  ;
        double takeProfitBuy = (MathAbs(NormalizeDouble(close1 - open0,Digits)))*TPExtra;//+ takeProfitBuy
       
        int ticketbuy = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask - stopLossPipsBuy ,close1+takeProfitBuy  ,"TheGap (spread "+spread+")",MAGICMA,0,Green);//- NormalizeDouble(Ask-Bid,Digits)
         //Alert("buy insidebar:" + insideBarFlag);
        if(ticketbuy > 0)
        {
            Ea_TradeOpen = true;
        }
     }
     
     
     // Sell 
     if ( close1 < (open0 )&& DayOfWeek() == 1  )//
     {
         double stopLossPipsSell = (MathAbs(NormalizeDouble(open0 - close1 ,Digits)))* SLClip ;//+ (50*Point)
         double takeProfitSell = (MathAbs(NormalizeDouble(open0 -close1,Digits)))* TPExtra; //-takeProfitSell
         
         int ticketsell = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid + stopLossPipsSell  ,close1-takeProfitSell ,"TheGap (spread "+spread+")",MAGICMA,0,Red); //+ NormalizeDouble(Ask-Bid,Digits)
        //Alert("sell insidebar:" + insideBarFlag);
         
        if(ticketsell > 0)
         {
            Ea_TradeOpen = true;
         }
     }
  
  }

  /*
  total = OrdersHistoryTotal();
   for(int x = OrdersHistoryTotal() - 1; x >= 0; x--)
   {
       OrderSelect(x, SELECT_BY_POS,MODE_HISTORY);
       if(OrderSymbol() == Symbol()&& (OrderMagicNumber() == MAGICMA) )
       {
   
         if(TimeCurrent() - OrderCloseTime()==1 && Ea_ReverseTradeOpen == false)
         {
            if(OrderType() == OP_SELL && StringFind(OrderComment(),"sl") != -1 )
            {
        
               int buy = OrderSend(Symbol(),OP_BUY,OrderLots(),Ask,Slippage,Ask - MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(),Digits)) ,Ask + MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(),Digits)) ,"TheGapR (spread "+ spread + ")",MAGICMA2,0,Green);//- NormalizeDouble(Ask-Bid,Digits)
               
               
            } 
            if(OrderType() == OP_BUY && StringFind(OrderComment(),"sl") != -1 )
            {
              
               int sell = OrderSend(Symbol(),OP_SELL,OrderLots(),Bid,Slippage,Bid + MathAbs(NormalizeDouble(OrderOpenPrice()-OrderTakeProfit(),Digits))  ,Bid - MathAbs(NormalizeDouble(OrderOpenPrice()-OrderTakeProfit(),Digits)) ,"TheGapR (spread "+ spread + ")",MAGICMA2,0,Red); //+ NormalizeDouble(Ask-Bid,Digits)
               
            }
  
         }
       }

    }*/
Comment(

  "Inside bar flagged : " + insideBarFlag + "\n",
  "Outside high : " + outsideHigh + "\n",
  "Outside low : " + outsideLow + "\n",
  "stand to gain buy : " + ((close1 - outsideHigh)/Point)+ "\n",
  "stand to gain sell : " + ((outsideLow - close1)/Point)+ "\n",
  "spread : " + spread + "\n",
  "opposite direction fakeout resulting in stoploss: "+count
  );
//----

   return(0);
  }
  
  
//+------------------------------------------------------------------+