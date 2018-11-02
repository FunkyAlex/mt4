//+---------------------------------------------------------------------------------+
//|                                  BreakoutFader.mq4                              |
//|                                  Copyright 2017, Alex Hutchinson                |
//|                                  http://www.alexhutchinson.info                 |
//|                                  version 1.0                                    |
//| positive pairs:                                                                 |
//|                                                                                 | 
//|                                                                                 |
//+---------------------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

extern double TPExtra = 0.7;
extern double SLClip =1;

#define MAGICMA 1
#define MAGICMA2 2

double closeLast;

bool insideBarFlag=false;
double outsideHigh;
double outsideLow;
double minimumEntryPips;
double spread;
double high1;
double low1;
double high2;
double low2;

double EMA8;
double EMA21;

double close1;


// external variables =============================
extern int Slippage=3;
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

   double Lots= 1;//AccountBalance()/10000;

   high1= iHigh(Symbol(),Period(),1);
   low1 = iLow(Symbol(),Period(),1);

   high2= iHigh(Symbol(),Period(),2);
   low2 = iLow(Symbol(),Period(),2);

   close1=iClose(Symbol(),Period(),1);

   EMA8=iMA(Symbol(),Period(),8,1,MODE_EMA,PRICE_CLOSE,1);
   EMA21=iMA(Symbol(),Period(),21,1,MODE_EMA,PRICE_CLOSE,1);

   minimumEntryPips=MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point) *3;
   spread=MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point);
   bool Ea_ReverseTradeOpen=false;
   bool Ea_TradeOpen=false;
   bool Ea_Sell_On= false;
   bool Ea_Buy_On = false;

   int Ea_Ticket_Nbr=0;
   int total=OrdersTotal();

   double Ea_Open_StopLoss=0;


   if(total>0)
     {
      for(int pos=0;pos<total;pos++)
        {
         // detects if the robot already has a trade(s) in progress
         if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
         if((OrderMagicNumber()==MAGICMA) && (OrderSymbol()==Symbol()))
           {
            Ea_TradeOpen=true;
            if(OrderStopLoss()==0)
            {
               string result1[]; 
               StringSplit(OrderComment(),',',result1);
               double sl = StrToDouble(result1[1]);
               double tp = StrToDouble(result1[2]);
               
               bool res1 = OrderModify(OrderTicket(),OrderOpenPrice(),sl,tp,0, Blue);
               if(!res1) Print("Error in OrderModify. Error code=",GetLastError());
               else Print("Order modified successfully.");
            }
            
           }
         if((OrderMagicNumber()==MAGICMA2) && (OrderSymbol()==Symbol()))
           {
            Ea_ReverseTradeOpen=true;
           }
        }
     }
   if(insideBarFlag==false && high1<high2 && low1>low2)
     {
      // inide bar is flagged
      insideBarFlag=true;
      outsideLow  = low2;
      outsideHigh = high2;

     }

   if(true)// if no open positions - check for possible trade-------------------------------------
     {

      // Buy //
      if(insideBarFlag==true && close1<outsideLow && spread <=4)//&& MathAbs(NormalizeDouble(outsideLow - close1,Digits)/Point) > minimumEntryPips
        {
         double stopLossPipsBuy= Ask- ((MathAbs(NormalizeDouble(outsideLow-close1,Digits)))*SLClip);
         double takeProfitBuy= outsideLow +((MathAbs(NormalizeDouble(outsideLow-Ask,Digits)))*TPExtra);//+ takeProfitBuy
                                                                                      // if(takeProfitBuy >= (30*Point())&& stopLossPipsBuy >= (30*Point()))
         // {
         int ticketbuy=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0,0,"Fader "+spread+","+stopLossPipsBuy+","+takeProfitBuy+"",MAGICMA,0,Green);//- NormalizeDouble(Ask-Bid,Digits)

         if(ticketbuy>0)
           {
            insideBarFlag=false;
            outsideHigh= 0.00;
            outsideLow = 0.00;
           }
         //}
        }

      // Sell 
      if(insideBarFlag==true && close1>outsideHigh && spread <=4)//&& MathAbs(NormalizeDouble(close1 - outsideHigh,Digits)/Point) > minimumEntryPips
        {
         double stopLossPipsSell=Bid + ((MathAbs(NormalizeDouble(close1-outsideHigh,Digits)))*SLClip);//+ (50*Point)
         double takeProfitSell= outsideHigh -((MathAbs(NormalizeDouble(Bid-outsideHigh,Digits))) *TPExtra); //-takeProfitSell
                                                                                          // if(takeProfitSell >= (30*Point())&& stopLossPipsSell >= (30*Point()))
         // {
         int ticketsell=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0,0,"Fader "+spread+","+stopLossPipsSell+","+takeProfitSell+"",MAGICMA,0,Red); //+ NormalizeDouble(Ask-Bid,Digits)

         if(ticketsell>0)
           {
            insideBarFlag=false;
            outsideHigh= 0.00;
            outsideLow = 0.00;
           }
         //  }
        }

     }
// Comment out for M1 testing
/*
   total=OrdersHistoryTotal();
   for(int x=OrdersHistoryTotal()-1; x>=0; x--)
     {
      OrderSelect(x,SELECT_BY_POS,MODE_HISTORY);
      if(OrderSymbol()==Symbol() && (OrderMagicNumber()==MAGICMA))
        {
         if(TimeCurrent()-OrderCloseTime()==1 && Ea_ReverseTradeOpen==false)
           {
            if(OrderType()==OP_SELL && StringFind(OrderComment(),"sl")!=-1)
              {
               int buy=OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,Ask-MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(),Digits)),Ask+MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(),Digits)),"Fader (spread "+spread+")",MAGICMA2,0,Green);//- NormalizeDouble(Ask-Bid,Digits)
              }
            if(OrderType()==OP_BUY && StringFind(OrderComment(),"sl")!=-1)
              {
               int sell=OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,Bid+MathAbs(NormalizeDouble(OrderOpenPrice()-OrderTakeProfit(),Digits)),Bid-MathAbs(NormalizeDouble(OrderOpenPrice()-OrderTakeProfit(),Digits)),"Fader (spread "+spread+")",MAGICMA2,0,Red); //+ NormalizeDouble(Ask-Bid,Digits)
              }
           }
        }
     }
*/
   Comment(

           "Inside bar flagged : "+insideBarFlag+"\n",
           "Outside high : "+outsideHigh+"\n",
           "Outside low : "+outsideLow+"\n",
           "stand to gain buy : "+((close1-outsideHigh)/Point)+"\n",
           "stand to gain sell : "+((outsideLow-close1)/Point)+"\n",
           "spread : "+spread+"\n",
           "min pips : "+(MarketInfo(Symbol(),MODE_STOPLEVEL)*Point)
           );
//----

   return(0);
  }

//+------------------------------------------------------------------+
