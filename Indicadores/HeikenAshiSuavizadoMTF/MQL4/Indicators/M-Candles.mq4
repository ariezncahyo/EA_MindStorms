//+------------------------------------------------------------------+
//|                                                    M-Candles.mq4 |
//|         îðèãèíàëüíàÿ èäåÿ äëÿ H1 è âûøå - Êèì Èãîðü Â. aka KimIV |
//|                                              http://www.kimiv.ru |
//|            Ïåðåïèñàë äëÿ ñòàíäàðòíûõ òàéìôðåéìîâ - Ìèõàèë Æèòíåâ |
//|                                                    ICQ 138092006 |
//|         2008.09.05  Íà ëþáîì ãðàôèêå ïîêàçûâàåò ñâå÷è ñòàðøèõ ÒÔ |
//+------------------------------------------------------------------+
//|                                                                  |
//|                                                    12 June 2013  |
//|                                                                  |
//|                                            Modified by RaptorUK  |
//|                                                                  |
//|  Modified to make painting bar 0 configurable, all modifications |
//|         marked RaptorUK                                          |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Æèòíåâ Ìèõàèë aka MikeZTN"
#property link      "ICQ 138092006"

#property indicator_chart_window

//------- Âíåøíèå ïàðàìåòðû ------------------------------------------
extern int TFBar       = 1440;           // Ïåðèîä ñòàðøèõ ñâå÷åê
extern bool bcgr       = true;           // objbcgr

extern int NumberOfBar = 20;           // Êîëè÷åñòâî ñòàðøèõ ñâå÷åê
extern color ColorUp   = DarkGreen;//0x003300;      // Öâåò âîñõîäÿùåé ñâå÷è
extern color ColorDown = Maroon;//0x000033;      // Öâåò íèñõîäÿùåé ñâå÷è

// added by RaptorUK
extern bool PaintBar0 = true;


//------- Ãëîáàëüíûå ïåðåìåííûå --------------------------------------

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void init() {
   int i;
   int StartBar = 0;   // added by RaptorUK
   
   if(!PaintBar0) StartBar = 1;   // RaptorUK added by RaptorUK

   
  for (i=StartBar; i<NumberOfBar; i++) {  // RaptorUK modded from 0 to StartBar
    ObjectDelete("BodyTF"+TFBar+"Bar"+i);
    ObjectDelete("ShadowTFh"+TFBar+"Bar" + i);
    ObjectDelete("ShadowTFl"+TFBar+"Bar" + i);

  }
  for (i=StartBar; i<NumberOfBar; i++) {  // modded from 0 to StartBar
    ObjectCreate("BodyTF"+TFBar+"Bar"+i, OBJ_RECTANGLE, 0, 0,0, 0,0);
    ObjectCreate("ShadowTFh"+TFBar+"Bar"+i, OBJ_TREND, 0, 0,0, 0,0);
    ObjectCreate("ShadowTFl"+TFBar+"Bar"+i, OBJ_TREND, 0, 0,0, 0,0);

  }
  Comment("");
}

//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
void deinit() {
  // Óäàëåíèå îáúåêòîâ
   int StartBar = 0;   // added by RaptorUK
   
   if(!PaintBar0) StartBar = 1;   // added by RaptorUK


  for (int i=StartBar; i<NumberOfBar; i++) {  // RaptorUK modded from 0 to StartBar
    ObjectDelete("BodyTF"+TFBar+"Bar"+i);
    ObjectDelete("ShadowTFh"+TFBar+"Bar" + i);
    ObjectDelete("ShadowTFl"+TFBar+"Bar" + i);

  }
  Comment("");
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start() {
  int shb=0, sh1=1, d;
  double   po, pc;       // Öåíû îòêðûòèÿ è çàêðûòèÿ ñòàðøèõ ñâå÷åê
  double   ph=0, pl=500; // Öåíû õàé è ëîó ñòàðøèõ ñâå÷åê
  datetime to, tc, ts;   // Âðåìÿ îòêðûòèÿ, çàêðûòèÿ è òåíåé ñòàðøèõ ñâå÷åê

   int StartBar = 0;   // RaptorUK added by RaptorUK
   
   if(!PaintBar0) StartBar = 1;   // RaptorUK added by RaptorUK

  
  bool OK_Period=false;   
  switch (TFBar)
  {    
    case 1:OK_Period=true;break;
    case 5:OK_Period=true;break;
    case 15:OK_Period=true;break;
    case 30:OK_Period=true;break;
    case 60:OK_Period=true;break;
    case 240:OK_Period=true;break;
    case 1440:OK_Period=true;break;
    case 10080:OK_Period=true;break;
    case 43200:OK_Period=true;break;
  }
  if (OK_Period==false)
     {
        Comment("TFBar != 1,5,15,30,60,240(H4), 1440(D1),10080(W1), 43200(MN) !");   
//      Comment("Âû ââåëè íåñòàíäàðòíóþ öèôðó òàéìôðåéìà TFBar! Íåîáõîäèìî ââåñòè îäíó èç ñëåäóþùèõ: 1,5,15,30,60,240,1440 è ò.ä.");   
       return(0);
     }
  if (Period()>TFBar) 
  {
    Comment("mCandles: TFBar<"+Period());//Çàäàâàåìûé ñòàíäàðòíûé ïåðèîä äîëæåí áûòü áîëüøå òåêóùåãî! (Òåêóùèé ðàâåí " + Period() + ")");
//  Comment("Çàäàâàåìûé ñòàíäàðòíûé ïåðèîä äîëæåí áûòü áîëüøå òåêóùåãî! (Òåêóùèé ðàâåí " + Period() + ")");
    return(0);
  }
    
    shb = StartBar;  // RaptorUK modded from 0 to StartBar
    
    // Áåæèì ïî ñòàðøèì ñâå÷êàì  
    while (shb<NumberOfBar) 
    {
    
    //to = iTime(Symbol(), TFBar, shb);
     // tc = iTime(Symbol(), TFBar, shb) + TFBar*60;
     //  po = iOpen(Symbol(), TFBar, shb);
     // pc = iClose(Symbol(), TFBar, shb);
     // ph = iHigh(Symbol(), TFBar, shb); 
     //  pl = iLow(Symbol(), TFBar, shb); 
      
      to = iTime(Symbol(), TFBar, shb);
      tc = iTime(Symbol(), TFBar, shb) + TFBar*60;
      po = iClose(Symbol(), TFBar, shb+1);
      pc = iClose(Symbol(), TFBar, shb);
      ph = MathMax(iHigh(Symbol(), TFBar, shb),MathMax(po,pc)); ; 
      pl = MathMin( iLow(Symbol(), TFBar, shb),MathMin(po,pc));; 
      
      //óñòàíàâëèâàåì  ðåêòàíãåëû
      ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_TIME1, to);  //âðåìÿ îòêðûòèÿ
      ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_PRICE1, ph); //öåíà îòêðûòèÿ
      ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_TIME2, tc);  //âðåìÿ çàêðûòèÿ
      ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_PRICE2, pl); //öåíà çàêðûòèÿ
      ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_WIDTH, 2);
      ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_BACK, bcgr);
      //óñòàíàâëèâàåì òåíè hl
   
 
 
 
      //óñòàíàâëèâàåì öâåòà äëÿ âñåõ îáúåêòîâ
      if (po<pc) {
          ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_COLOR, ColorUp);
          ObjectSet("ShadowTFh"+TFBar+"Bar"+shb, OBJPROP_COLOR, ColorUp);
          ObjectSet("ShadowTFl"+TFBar+"Bar"+shb, OBJPROP_COLOR, ColorUp);
 
        } else {
          ObjectSet("BodyTF"+TFBar+"Bar"+shb, OBJPROP_COLOR, ColorDown);
          ObjectSet("ShadowTFh"+TFBar+"Bar"+shb, OBJPROP_COLOR, ColorDown);
          ObjectSet("ShadowTFl"+TFBar+"Bar"+shb, OBJPROP_COLOR, ColorDown);

        }
      shb++;
     }       
      
  
  return(0);
}
//+------------------------------------------------------------------+