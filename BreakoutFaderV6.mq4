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
extern double SLClip = 1.0;

#define MAGICMA 1
#define MAGICMA2 2

double closeLast;

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
double open1;

int fakeoutLowSell;
int fakeoutHighSell;
int fakeoutLowBuy;
int fakeoutHighBuy;
int fakeoutLow;
int fakeoutHigh;
int count;


// external variables =============================
extern int Slippage = 3;
//==================================================

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
  fakeoutLowSell = 0;
fakeoutHighSell =0 ;
fakeoutLowBuy = 0;
fakeoutLowBuy =0;
fakeoutLow = 0;
fakeoutHigh = 0;

count=0;
insideBarFlag = false;
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

EMA8 = iMA(Symbol(),Period(),8,1,MODE_EMA,PRICE_CLOSE,1);
EMA21 = iMA(Symbol(),Period(),21,1,MODE_EMA,PRICE_CLOSE,1);


minimumEntryPips = MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point) *3;
spread = MathAbs(NormalizeDouble(Ask-Bid,Digits)/Point);

bool Ea_TradeOpen = false;
bool Ea_ReverseTradeOpen = false;
bool Ea_Sell_On = false;
bool Ea_Buy_On = false;

int Ea_Ticket_Nbr = 0;
int total=OrdersTotal();

double Ea_Open_StopLoss = 0;



if (total > 0)
  {
  for(int pos=0;pos<total;pos++)
    {
    // detects if the robot already has a trade(s) in progress
     if(OrderSelect(pos,SELECT_BY_POS)==false) continue;
       if((OrderMagicNumber() == MAGICMA) && (OrderSymbol() == Symbol())) 
        {
         Ea_TradeOpen=true;
         if(OrderStopLoss()==0)
         {
            string result1[]; 
            StringSplit(OrderComment(),',',result1);
            double sl = StrToDouble(result1[1]);
            double tp = StrToDouble(result1[2]);
            
            if(OrderType() == OP_BUY)
            {
               bool res1 = OrderModify(OrderTicket(),OrderOpenPrice(),Ask - sl,tp,0, Blue);
               if(!res1) Print("Error in OrderModify Buy. Ticket: " +OrderTicket() + " Error code=",GetLastError());
               else Print("Order modified successfully.");
            }
            else
            {
               bool res2 = OrderModify(OrderTicket(),OrderOpenPrice(),Bid + sl,tp,0, Blue);
               if(!res2) Print("Error in OrderModify Sell. Ticket: " +OrderTicket() + " Error code=",GetLastError());
               else Print("Order modified successfully.");
            }
         }
         
        }
        if((OrderMagicNumber() == MAGICMA2) && (OrderSymbol() == Symbol())) 
        {
         Ea_TradeOpen=true;
         if(OrderStopLoss()==0)
         {
            string result2[]; 
            StringSplit(OrderComment(),',',result2);
            double sl2 = StrToDouble(result2[1]);
            double tp2 = StrToDouble(result2[2]);
            
            if(OrderType() == OP_BUY)
            {
               bool res3 = OrderModify(OrderTicket(),OrderOpenPrice(),Ask - sl2,Ask + tp2,0, Blue);
               if(!res3) Print("Error in OrderModify Buy. Ticket: " +OrderTicket() + " Error code=",GetLastError());
               else Print("Order modified successfully.");
            }
            else
            {
               bool res4 = OrderModify(OrderTicket(),OrderOpenPrice(),Bid + sl2,Bid - tp2,0, Blue);
               if(!res4) Print("Error in OrderModify Sell. Ticket: " +OrderTicket() + " Error code=",GetLastError());
               else Print("Order modified successfully.");
            }
         }
         
        }
        if((OrderMagicNumber()==MAGICMA2) && (OrderSymbol()==Symbol()))
        {
             Ea_ReverseTradeOpen=true;
        } 
      }
    } 
if (insideBarFlag == false && high1 <= high2 && low1 >= low2)
{
   // inide bar is flagged
   insideBarFlag = true;
   outsideLow  = low2;
   outsideHigh = high2;

}

if ( insideBarFlag == true && close1 < outsideHigh && high1 < outsideHigh && close1 > outsideLow && low1 < outsideLow )
{
   fakeoutLow ++;
   
}
else if (insideBarFlag == true && close1 < outsideHigh && high1 > outsideHigh && close1 > outsideLow && low1 > outsideLow )
{
    fakeoutHigh ++;
    
}

if (true)// if no open positions - check for possible trade-------------------------------------
  {
 
     // Buy //
     if ( insideBarFlag == true && close1 < outsideLow && spread <=3 )//&& MathAbs(NormalizeDouble(outsideLow - close1,Digits)/Point) > minimumEntryPips
     {
        double stopLossPipsBuy = (MathAbs(NormalizeDouble(outsideLow - close1 ,Digits)))*SLClip;
        double takeProfitBuy = (MathAbs(NormalizeDouble(outsideLow - close1,Digits)))*TPExtra;//+ takeProfitBuy
        //Alert(stopLossPipsBuy + " " + spread);
       if(stopLossPipsBuy > NormalizeDouble(Ask-Bid,Digits))// is stop loss bigger than spread
       {
           int ticketbuy = OrderSend(Symbol(),OP_BUY,Lots,Ask,Slippage,0 ,0  ,"F. "+spread+","+(stopLossPipsBuy)+","+(outsideLow + takeProfitBuy)+", "+fakeoutLow+","+fakeoutHigh+")",MAGICMA,0,Green);//- NormalizeDouble(Ask-Bid,Digits)
            //Alert("buy insidebar:" + insideBarFlag);
           if(ticketbuy > 0)
           {
               insideBarFlag = false;
               outsideHigh = 0.00;
               outsideLow = 0.00;
               fakeoutHigh = 0;
               fakeoutLow = 0;
           }
        }
     }
     
     
     // Sell 
     if ( insideBarFlag == true && close1 > outsideHigh && spread <=3 )//&& MathAbs(NormalizeDouble(close1 - outsideHigh,Digits)/Point) > minimumEntryPips
     {
         double stopLossPipsSell = (MathAbs(NormalizeDouble(close1 - outsideHigh,Digits)))*SLClip ;//+ (50*Point)
         double takeProfitSell = (MathAbs(NormalizeDouble(close1 -outsideHigh,Digits)))* TPExtra; //-takeProfitSell
         if(stopLossPipsSell > NormalizeDouble(Ask-Bid,Digits))// is stop loss bigger than spread
         {
            int ticketsell = OrderSend(Symbol(),OP_SELL,Lots,Bid,Slippage,0  ,0 ,"F. "+spread+","+ (stopLossPipsSell)+","+(outsideHigh - takeProfitSell)+", "+fakeoutLow+","+fakeoutHigh+")",MAGICMA,0,Red); //+ NormalizeDouble(Ask-Bid,Digits)
           //Alert("sell insidebar:" + insideBarFlag);
            
           if(ticketsell > 0)
            {
               insideBarFlag = false;
               outsideHigh = 0.00;
               outsideLow = 0.00;
               fakeoutHigh = 0;
               fakeoutLow = 0;
            }
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
            
            
               string result3[]; 
               StringSplit(OrderComment(),',',result3);
               if(StrToInteger(result3[3]) > 0) {fakeoutLowSell++;}
               if(StrToInteger(result3[4]) > 0) {fakeoutHighSell++;}
                //Alert("sell reverse");
                
                if(MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(), Digits)) > NormalizeDouble(Ask-Bid,Digits))
                {
                  Print(MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(), Digits)) +" " + NormalizeDouble(Ask-Bid,Digits));
                  int buy = OrderSend(Symbol(),OP_BUY,OrderLots(),Ask,Slippage,0  ,0  ,"FR ("+ spread + "),"+MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(), Digits))+","+MathAbs(NormalizeDouble(OrderTakeProfit()-OrderOpenPrice(),Digits)),MAGICMA2,0,Green);//- NormalizeDouble(Ask-Bid,Digits)
                }
               
            } 
            if(OrderType() == OP_BUY && StringFind(OrderComment(),"sl") != -1 )
            {
               //Alert("buy reverse");
                              string result4[]; 
               StringSplit(OrderComment(),',',result4);
               if(StrToInteger(result3[3]) > 0) {fakeoutLowBuy++;}
               if(StrToInteger(result3[4]) > 0) {fakeoutHighBuy++;}
               if(MathAbs(NormalizeDouble(OrderOpenPrice()-OrderTakeProfit(), Digits)) > NormalizeDouble(Ask-Bid,Digits))
               {
                  int sell = OrderSend(Symbol(),OP_SELL,OrderLots(),Bid,Slippage,0 ,0 ,"FR ("+ spread + "),"+MathAbs(NormalizeDouble(OrderOpenPrice()-OrderTakeProfit(), Digits))+","+MathAbs(NormalizeDouble(OrderOpenPrice()-OrderTakeProfit(),Digits)),MAGICMA2,0,Red); //+ NormalizeDouble(Ask-Bid,Digits)
               }
            }
             Print("fakeout opposite direction resulting in stoploss (sell): "+fakeoutHighSell);
             Print("fakeout same direction resulting in stoploss (sell): "+fakeoutLowSell);
             Print("fakeout opposite direction resulting in stoploss (buy): "+fakeoutLowBuy);
             Print("fakeout same direction resulting in stoploss (buy): "+fakeoutHighBuy);
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