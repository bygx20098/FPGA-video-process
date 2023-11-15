import argparse
import os.path
import shutil
import fileinput
import re
import subprocess
import sys
import time
import os
import glob
import codecs
from pathlib import Path
from shutil import which

binDl = []
binDbl= []

def is_tool(name):
    """Check whether `name` is on PATH and marked as executable."""

    return which(name) is not None

def genMEM(args,cp,dp):

    if(args.bin[0] == '/' or args.bin[1] == ':'):
        fb=Path(args.bin)
    else:
        fb=Path(cp,args.bin)
    #read from application bin
    try:
        with open(fb, "rb") as f:
            while True:
                binD = f.read(1)
                if not binD:
                    break
                binDl.append(binD)
    except IOError:
        print('[EFX_ERR]: Application binary file '+str(fb)+' was not found!')
        print('[EFX_ERR]: Aborting simulation...')
        quit()
    
    for i in binDl:
        binDv = ord(i)
        binDb = '{0:02x}'.format(binDv)
        binDbl.append(binDb)
    
    ft=len(binDbl) % 16 
    if(ft != 0):
        for x in range(16-ft):
            binDbl.append('00')

    words=''
    wordsl=[]
    r=0
    while (r < len(binDbl)):
        for n in range(r, r+16):
            words = binDbl[n]+words
        wordsl.append(words)
        words=''
        r=r+16

    #calculate address
    adr=int(4096/16)
    adrx=hex(adr).split('x')[-1]
    wordsl.insert(0,'@'+str(adrx))

    dt=Path(dp,'MEM.TXT')
    fm=open(dt,'w')
    for l in range(0,len(wordsl)):
        fm.write(wordsl[l]+'\n')
    fm.close()

def binSplit (start, romHex, ramsize):
    rom_l = []
    for x in range (start, len(binDbl), 8):
        rom_l.append(binDbl[x])
        
    padNumber = (ramsize >> 3)-len(rom_l)
    
    for x in range (0, padNumber):
        rom_l.append("00000000")

    f = open(romHex ,'w')
    for x in range(0, len(rom_l)):
        f.write(rom_l[x]+"\n")
    f.close

def genBin(args,cp,dp):
    if(args.imem[0] == '/' or args.imem[1] == ':'):
        fb=Path(args.imem)
    else:
        fb=Path(cp,args.imem)
    #read from application bin
    try:
        with open(fb, "rb") as f:
            while True:
                binD = f.read(1)
                if not binD:
                    break
                binDl.append(binD)

    except IOError:
        print('[EFX_ERR]: Application binary file '+str(fb)+' was not found!')
        print('[EFX_ERR]: Aborting simulation...')
        quit()
    
    for i in binDl:
        binDv = ord(i)
        binDb = '{0:08b}'.format(binDv)
        binDbl.append(binDb)

    bp0=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol0.bin')
    bp1=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol1.bin')
    bp2=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol2.bin')
    bp3=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol3.bin')
    bp4=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol4.bin')
    bp5=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol5.bin')
    bp6=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol6.bin')
    bp7=Path(dp,'EfxSapphireSoc.v_toplevel_system_ramA_logic_ram_symbol7.bin')

    ramSize = 4096
    binSplit(0, bp0, ramSize)
    binSplit(1, bp1, ramSize)
    binSplit(2, bp2, ramSize)
    binSplit(3, bp3, ramSize)
    binSplit(4, bp4, ramSize)
    binSplit(5, bp5, ramSize)
    binSplit(6, bp6, ramSize)
    binSplit(7, bp7, ramSize)

def genMEM_IM(args,cp,dp):

    fb=Path(cp,args.bin)
    #read from application bin
    try:
        with open(fb, "rb") as f:
            while True:
                binD = f.read(1)
                if not binD:
                    break
                binDl.append(binD)

    except IOError:
        print('[EFX_ERR]: Application binary file '+str(fb)+' was not found!')
        print('[EFX_ERR]: Aborting simulation...')
        quit()
    
    for i in binDl:
        binDv = ord(i)
        binDb = '{0:02x}'.format(binDv)
        binDbl.append(binDb)
    
    #calculate address
    adr=3670016
    adrx=hex(adr).split('x')[-1]
    binDbl.insert(0,'@'+str(adrx))

    dt=Path(dp,'MEM_IM.TXT')
    fm=open(dt,'w')
    for l in range(0,len(binDbl)):
        fm.write(binDbl[l]+'\n')
    fm.close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-b',
                        '--bin',
                        default=None,
                        help='(Target Ext Mem)Location to Application bin(Relative Path)')
    parser.add_argument('-i',
                        '--imem',
                        default=None,
                        help='(Target Int Mem)Location to Application bin(Relative Path)')
    parser.add_argument('-f',
                        '--fullflow',
                        action='store_true',
                        help='Includes SPI flash loading in simulation')

    args = parser.parse_args()
    #check efinity environment
    print('[EFX_INFO]: Checking environment')
    try:
        os.environ['EFINITY_HOME']
    except:
        print('[EFX_ERR]: Neither EFINITY_HOME nor EFXIPM_HOME is set.')
        print('[EFX_ERR]: You should source from Efinity setup.sh or setup.bat')
        quit()

    #check if vsim executable valid
    if(os.name == 'nt'):
        if(is_tool('vsim.exe') == False):
            print("[EFX_ERR]: vsim executable not found")
            quit()
    else:
        if(is_tool('vsim') == False):
            print("[EFX_ERR]: vsim executable not found")
            quit()

    #check bin file is valid for simulation
    if(args.bin != None and args.bin[-4:] != ".bin"):
        print('[EFX_ERR]: Application file must be in .bin format')
        print('[EFX_ERR]: Eg. apb3Demo.bin')
        quit()

    if(args.imem != None and args.imem[-4:] != ".bin"):
        print('[EFX_ERR]: Application file must be in .bin format')
        print('[EFX_ERR]: Eg. apb3Demo.bin')
        quit()

    if(args.fullflow == True):
        print('[EFX_INFO]: This simulation run with SPI flash bootloader sequence')
    else:
        print('[EFX_INFO]: This simulation bypass SPI flash bootloader sequence')

    if(args.bin == None):
        print('[EFX_INFO]: This simulation run with default \"hello world\" application')
    elif(args.imem):
        print('[EFX_INFO]: This simulation run with custom application (target internal memory) provided by user')
    else:
        print('[EFX_INFO]: This simulation run with custom application (target external memory) provided by user')

    #check directory
    cp=os.getcwd()
    dest_sim=Path(cp, 'SimSOC')
    tb_sim=Path(dest_sim, 'tb_soc.v')

    #move file to new folder
    if os.path.exists(dest_sim):
        print('[EFX_INFO]: Deleting old \"SimSOC\" folder')
        shutil.rmtree(dest_sim)
    print('[EFX_INFO]: Creating new folder \"SimSOC\"')
    os.mkdir(dest_sim)

    print('[EFX_INFO]: Copying files to \"SimSOC\" folder')
    if(args.fullflow == True):
        for d in glob.glob(r'../*.bin'):
            shutil.copy(d, dest_sim)
    else:
        for d in glob.glob(r'*.bin'):
            shutil.copy(d, dest_sim)

    for d in glob.glob(r'*.v'):
        shutil.copy(d, dest_sim)

    for d in glob.glob(r'*.vh'):
        shutil.copy(d, dest_sim)

    for d in glob.glob(r'*.TXT'):
        shutil.copy(d, dest_sim)

    for d in glob.glob(r'*.do'):
        shutil.copy(d, dest_sim)
    
    # Copy modelsim encrypted RTL
    shutil.copytree("modelsim", Path(dest_sim, "modelsim"))

    #check if any bin file parse in
    if(args.bin == None and args.imem == None):
        pass
    else:
        print('[EFX_INFO]: Generating new memory initialization file(s) for custom application')
        if(args.fullflow == False):
            if(args.bin != None):
                genMEM(args,cp,dest_sim)
            else:
                genBin(args,cp,dest_sim)
        else:   
            genMEM_IM(args,cp,dest_sim)

    #skip original sequences if custom bin found
    if(args.bin == None and args.imem == None):
        pass
    else:
        print('[EFX_INFO]: Modifying testbench to skip default driver and monitor sequence for \"hello world\" application')
        tmpf = Path(dest_sim, 'tb_soc.v'+'.tmp')
        with codecs.open(tb_sim, 'r', encoding='utf-8') as fi, \
            codecs.open(tmpf, 'w', encoding='utf-8') as fo:

            for line in fi:
            #new_line = do_processing(line) # do your line processing here
                new_line = line.replace('//`define SKIP_TEST', '`define SKIP_TEST')
                fo.write(new_line)

        os.remove(tb_sim) # remove original
        os.rename(tmpf, tb_sim) # rename temp to original name

    print('[EFX_INFO]: Starting simulator')
    #run simulation
    os.chdir(dest_sim)    
    if(os.name == 'nt'):
        os.system('vsim.exe -do tb_soc.do')
    else:
        os.system('vsim -do tb_soc.do')


if __name__ == '__main__':
    main()


