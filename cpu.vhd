--------------------------------------------------------------------------------
--! @file cpu.vhd
--! @brief This contains the CPU/main memory instances
--!
--! @author     Richard James Howe.
--! @copyright  Copyright 2013 Richard James Howe.
--! @license    LGPL    
--! @email      howe.r.j.89@gmail.com
--------------------------------------------------------------------------------

library ieee,work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.util.memory;

entity cpu is
	generic(
		number_of_interrupts: positive := 8);
	port(
		-- synthesis translate_off
		debug_pc:         out std_logic_vector(12 downto 0);
		debug_insn:       out std_logic_vector(15 downto 0);
		debug_mem_dwe:    out std_logic:= '0';   
		debug_mem_din:    out std_logic_vector(15 downto 0);
		debug_mem_dout:   out std_logic_vector(15 downto 0);
		debug_mem_daddr:  out std_logic_vector(12 downto 0);
		-- synthesis translate_on

		clk:        in   std_logic;
		rst:        in   std_logic;

		-- CPU External interface, I/O
		cpu_wait:   in   std_logic; -- Halt the CPU
		cpu_wr:     out  std_logic;
		cpu_re:     out  std_logic; -- hardware *READS* can have side effects
		cpu_din:    in   std_logic_vector(15 downto 0);
		cpu_dout:   out  std_logic_vector(15 downto 0):= (others => 'X');
		cpu_daddr:  out  std_logic_vector(15 downto 0):= (others => 'X');
		-- Interrupts
		cpu_irq:    in   std_logic;
		cpu_irc:    in   std_logic_vector(number_of_interrupts - 1 downto 0));
end;

architecture behav of cpu is
	--! CPU, Internal Memory interface to RAM/ROM
	----! This should interface with some dual port RAM, it forms the
	----! brains of the system; a CPU with some RAM that should contain
	----! the bootloader (or the entire system).

	--! memory constants
	constant addr_bitlen: positive := 13;
	constant data_bitlen: positive := 16;
	constant filename:    string   := "mem_h2.hexadecimal";
	constant filetype:    string   := "hex";
	--! memory <-> cpu signals
	signal pc:           std_logic_vector(addr_bitlen - 1 downto 0):= (others => '0'); -- Program counter
	signal insn:         std_logic_vector(data_bitlen - 1 downto 0):= (others => '0'); -- Instruction issued by program counter
	signal mem_dwe:      std_logic:= '0';   -- Read/Write toggle, 0=Read, 1=Write
	signal mem_din:      std_logic_vector(data_bitlen - 1 downto 0):= (others => '0');
	signal mem_dout:     std_logic_vector(data_bitlen - 1 downto 0):= (others => '0');
	signal mem_daddr:    std_logic_vector(addr_bitlen - 1 downto 0):= (others => '0');

	signal dptr:         std_logic_vector(15 downto 0):= (others => '0');

	signal processed_irq: std_logic:= '0';
	signal processed_irc: std_logic_vector(number_of_interrupts - 1 downto 0):=(others=>'0');
begin
	-- synthesis translate_off
	debug_pc          <= pc;
	debug_insn        <= insn;
	debug_mem_dwe     <= mem_dwe;
	debug_mem_din     <= mem_din;
	debug_mem_dout    <= mem_dout;
	debug_mem_daddr   <= mem_daddr;
	-- synthesis translate_on

	irqh_instance: entity work.irqh
	generic map(
		number_of_interrupts => number_of_interrupts)
	port map(
		clk       =>    clk,
		rst       =>    rst,

		raw_irq   =>    cpu_irq,
		raw_irc   =>    cpu_irc,

		processed_irq => processed_irq,
		processed_irc => processed_irc);

	-- The actual CPU instance (H2)
	h2_instance: entity work.h2
	generic map(
		number_of_interrupts => number_of_interrupts)
	port map(
		clk       =>    clk,
		rst       =>    rst,

		-- External interface with the 'outside world'
		cpu_wait  =>  cpu_wait,
		io_wr     =>  cpu_wr,
		io_re     =>  cpu_re,
		io_din    =>  cpu_din,
		io_dout   =>  cpu_dout,
		io_daddr  =>  cpu_daddr,

		irq       =>  processed_irq,
		irc       =>  processed_irc,

		-- Instruction and instruction address to CPU
		pco       =>    pc, 
		insn      =>    insn,  
		-- Fetch/Store
		dwe       =>    mem_dwe,
		din       =>    mem_din,
		dout      =>    mem_dout,
		daddr     =>    mem_daddr,
		-- Data pointer
		dptr      =>    dptr);

	--! Dual port RAM for the CPU, acts as bootloader or
	--! contains the full system software
	mem_h2_instance: entity work.memory
	generic map(
		addr_bitlen   => addr_bitlen,
		data_bitlen   => data_bitlen,
		filename      => filename,
		filetype      => filetype)
	port map(
		-- Port A, Read only, CPU instruction/address
		a_clk   =>    clk,
		a_dwe   =>    '0',
		a_addr  =>    pc,
		a_din   =>    (others => '0'),
		a_dout  =>    insn,
		-- Port B, Read/Write controlled by CPU instructions
		b_clk   =>    clk,
		b_dwe   =>    mem_dwe,
		b_addr  =>    mem_daddr,
		b_din   =>    mem_dout,
		b_dout  =>    mem_din);

end architecture;
