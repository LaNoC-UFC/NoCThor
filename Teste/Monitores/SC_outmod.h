#ifndef OUT_MOD
#define OUT_MOD

#include "SC_common.h"

SC_MODULE(outputmodule)
{
	sc_in<sc_logic> clock;
	sc_in<sc_logic> reset;
	
	sc_in<sc_lv<TAM_FLIT> > indata[NUM_EP];
	sc_in<sc_logic> intx[NUM_EP];
	
	int inline inTx(int Indice)
	{
		return (intx[Indice] == SC_LOGIC_1)?1:0;
	}

	unsigned long int inline inData(int Indice)
	{
		return indata[Indice].read().to_uint();
	}

	unsigned long int inline address(int index)
	{
		unsigned long int x, y, addr;
		x = index/NUM_ROT_X;
		y = index%NUM_ROT_Y;
		addr = (x << (TAM_FLIT/2)) + y;
		return addr;
	}

	unsigned long int CurrentTime;

	void TrafficStalker();
	void Timer();

	SC_CTOR(outputmodule) :
	reset("reset"),
	clock("clock")
	{
		CurrentTime = 0;

		SC_CTHREAD(TrafficStalker, clock.neg());
		//watching(reset.delayed()== true);

		SC_METHOD(Timer);
		sensitive_pos << clock;
		dont_initialize();

	}
};

void outputmodule::Timer()
{
	++CurrentTime;
}

void outputmodule::TrafficStalker()
{
	CurrentTime = 0;
	FILE* Output[NUM_EP];

	unsigned long int CurrentFlit[NUM_EP];
	int EstadoAtual[NUM_EP],Size[NUM_EP];
	int i, j, Index;
	char temp[100];

	char TimeTargetHex[NUM_EP][100];
	unsigned long int TimeTarget[NUM_EP];
	unsigned long int TimeSourceCore[NUM_EP];
	unsigned long int TimeSourceNet[NUM_EP];

	struct timeb tp;
	int segundos_inicial, milisegundos_inicial;
	int segundos_final, milisegundos_final;
	unsigned long int TimeFinal;

//-----------------TIME--------------------------------//
	//captura o tempo
	//ftime(&tp);
	//armazena o tempo inicial
	segundos_inicial=tp.time;
	milisegundos_inicial=tp.millitm;
//-----------------------------------------------------//

	for(i=0; i<NUM_EP; i++)
	{
		sprintf(temp,"Out/out%0*X.txt",TAM_FLIT/4,address(NUM_EP -1 - i));
		Output[i] = fopen(temp,"w");
		Size[i] = 0;
		EstadoAtual[i] = 1;
	}

	while(true)
	{
		for(Index = 0; Index<NUM_EP;Index++)
		{

			if(inTx(Index)==1)
			{
				if(EstadoAtual[Index] == 1)//captura o header do pacote
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index],"%0*X",(int)TAM_FLIT/4,CurrentFlit[Index]);

					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index] == 2)//captura o tamanho do payload
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index]," %0*X",(int)TAM_FLIT/4,CurrentFlit[Index]);

					Size[Index] = CurrentFlit[Index];
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index] == 3)//captura o nodo origem
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index]," %0*X",(int)TAM_FLIT/4,CurrentFlit[Index]);

					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index]>=4 && EstadoAtual[Index]<=7)//captura o timestamp do nodo origem
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index]," %0*X",(int)TAM_FLIT/4,CurrentFlit[Index]);

					if(EstadoAtual[Index]==4) TimeSourceCore[Index]=0;

					TimeSourceCore[Index] += (unsigned long int)(CurrentFlit[Index] * pow(2,((7 - EstadoAtual[Index])*TAM_FLIT)));

					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index] == 8 || EstadoAtual[Index] == 9)//captura o número de sequencia do pacote
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index]," %0*X",(int)TAM_FLIT/4,CurrentFlit[Index]);

					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index]>=10 && EstadoAtual[Index]<=13)//captura o timestamp do entrada na rede
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index]," %0*X",(int)TAM_FLIT/4,CurrentFlit[Index]);

					if(EstadoAtual[Index]==10) TimeSourceNet[Index]=0;

					TimeSourceNet[Index] += (unsigned long int)(CurrentFlit[Index] * pow(2,((13 - EstadoAtual[Index])*TAM_FLIT)));

					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index]==14)//captura o payload
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index]," %0*X",(int)TAM_FLIT/4,CurrentFlit[Index]);

					Size[Index]--;

					if(Size[Index]==0)//fim do pacote
					{
						//Tempo de chegada no destino
						TimeTarget[Index]= CurrentTime;
						sprintf(TimeTargetHex[Index], "%0*X",TAM_FLIT,TimeTarget[Index]);
						for(i=0,j=0;i<TAM_FLIT;i++,j++)
						{
							temp[j]=TimeTargetHex[Index][i];
							if(j==TAM_FLIT/4-1)
							{
								temp[TAM_FLIT/4]='\0';
								fprintf(Output[Index]," %s",temp);
								j=-1; //  porque na iteracao seguinte j será 0.
							}
						}

						//Tempo em que o nodo origem deveria inserir o pacote na rede (em decimal)
						fprintf(Output[Index]," %d",TimeSourceCore[Index]);

						//Tempo em que o pacote entrou na rede (em decimal)
						fprintf(Output[Index]," %d",TimeSourceNet[Index]);

						//Tempo de chegada do pacote no destino (em decimal)
						fprintf(Output[Index]," %d",TimeTarget[Index]);

						//latência desde o tempo de criação do pacote (em decimal)
						fprintf(Output[Index]," %d",(TimeTarget[Index]-TimeSourceCore[Index]));

					//-----------------TIME--------------------------------//
						//captura o tempo de simulacao em milisegundos
						//ftime(&tp);

						//armazena o tempo final
						segundos_final=tp.time;
						milisegundos_final=tp.millitm;

						TimeFinal=(segundos_final*1000 + milisegundos_final) - (segundos_inicial*1000+milisegundos_inicial);
					//-----------------------------------------------------//

						fprintf(Output[Index]," %ld\n",TimeFinal);
						EstadoAtual[Index] = 1;
					}
				}
			}
		}
		wait();
	}
}

#endif
