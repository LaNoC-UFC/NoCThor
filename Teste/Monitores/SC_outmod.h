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
	unsigned long int* Packet[NUM_EP];
	char nullPack[NUM_EP];
	
	unsigned long int arrived = 0, nPack = 0;
	FILE* npack = NULL;

	for(Index=0; Index<NUM_EP; Index++) {
		Output[Index] = NULL;
		Packet[Index]=(unsigned long int*) calloc( sizeof(unsigned long int) , 9); // 9 eh o tamanho do pacote ateh o numero de sequencia
		Size[Index] = 0;
		EstadoAtual[Index] = 0;
	}

	while(true)
	{
		for(Index = 0; Index<NUM_EP; Index++)
		{

			if(inTx(Index)==1)
			{
				if(EstadoAtual[Index] == 0)//captura o header do pacote
				{
					Packet[Index][EstadoAtual[Index]] = (unsigned long int)inData(Index);
					
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index] == 1)//captura o tamanho do payload
				{
					Packet[Index][EstadoAtual[Index]] = (unsigned long int)inData(Index);

					Size[Index] = Packet[Index][EstadoAtual[Index]];
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index] == 2)//captura o nodo origem
				{
					Packet[Index][EstadoAtual[Index]] = (unsigned long int)inData(Index);

					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index]>=3 && EstadoAtual[Index]<=6)//captura o timestamp do nodo origem
				{
					Packet[Index][EstadoAtual[Index]] = (unsigned long int)inData(Index);

					if(EstadoAtual[Index]==3) TimeSourceCore[Index]=0;

					TimeSourceCore[Index] += (unsigned long int)(Packet[Index][EstadoAtual[Index]] * pow(2,((6 - EstadoAtual[Index])*TAM_FLIT)));

					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index] == 7 || EstadoAtual[Index] == 8)//captura o número de sequencia do pacote
				{
					Packet[Index][EstadoAtual[Index]] = (unsigned long int)inData(Index);

					if(EstadoAtual[Index] == 8) {
						
						nullPack[Index] = (Packet[Index][7] == 0 && Packet[Index][8] == 0);
						if(!nullPack[Index]) {
							if(Output[Index] == NULL) {
								sprintf(temp,"Out/out%0*X.txt",TAM_FLIT/4,address(NUM_EP-1-Index));
								Output[Index] = fopen(temp,"w");
							}
							for(i=0; i<=8; i++)
								fprintf(Output[Index],"%0*X ",(int)TAM_FLIT/4,Packet[Index][i]);
						}
						else
							EstadoAtual[Index] = 13; // vai ser incrementado
					}
					
					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index]>=9 && EstadoAtual[Index]<=12)//captura o timestamp do entrada na rede
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index],"%0*X ",(int)TAM_FLIT/4,CurrentFlit[Index]);

					if(EstadoAtual[Index]==9) TimeSourceNet[Index]=0;

					TimeSourceNet[Index] += (unsigned long int)(CurrentFlit[Index] * pow(2,((12 - EstadoAtual[Index])*TAM_FLIT)));

					Size[Index]--;
					EstadoAtual[Index]++;
				}
				
				else if(EstadoAtual[Index]==13)//captura o payload
				{
					CurrentFlit[Index] = (unsigned long int)inData(Index);
					fprintf(Output[Index],"%0*X ",(int)TAM_FLIT/4,CurrentFlit[Index]);

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
								fprintf(Output[Index],"%s ",temp);
								j=-1; //  porque na iteracao seguinte j será 0.
							}
						}

						//Tempo em que o nodo origem deveria inserir o pacote na rede (em decimal)
						fprintf(Output[Index],"%d ",TimeSourceCore[Index]);

						//Tempo em que o pacote entrou na rede (em decimal)
						fprintf(Output[Index],"%d ",TimeSourceNet[Index]);

						//Tempo de chegada do pacote no destino (em decimal)
						fprintf(Output[Index],"%d ",TimeTarget[Index]);

						//latência desde o tempo de criação do pacote (em decimal)
						fprintf(Output[Index],"%d",(TimeTarget[Index]-TimeSourceCore[Index]));

						EstadoAtual[Index] = 0;
						
						arrived++;
					}
				}
				else if(EstadoAtual[Index]==14) //descarta flits
				{
					//CurrentFlit[Index] = (unsigned long int)inData(Index);

					Size[Index]--;
					if(Size[Index]==0) {//fim do pacote
						EstadoAtual[Index] = 0;
						arrived++;
					}
				}
			}
		}
		wait();
		if(npack == NULL) {
			npack = fopen("npack","r");
			if(npack != NULL) fscanf(npack,"%ld",&nPack);
			//cout << "Arrived = " << arrived << endl;
		} else if(arrived >= nPack) {
			for(i=0; i<NUM_EP; i++)
				if(Output[i] != NULL) fclose(Output[i]);
			sc_stop();
		}

	}
}

#endif
