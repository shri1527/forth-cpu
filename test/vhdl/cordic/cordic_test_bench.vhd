-------------------------------------------------------------------------------
--! @file cordic_test_bench.vhd
--! @brief CORDIC test bench only.
--! @author         Richard James Howe.
--! @copyright      Copyright 2013 Richard James Howe.
--! @license        LGPL      
--! @email          howe.r.j.89@gmail.com
-------------------------------------------------------------------------------
library ieee,work,std;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity cordic_test_bench is
end entity;

architecture simulation of cordic_test_bench is
  constant clk_freq:     positive                         :=  1000000000;
  constant clk_period:   time                             :=  1000 ms / clk_freq;

  signal wait_flag:       std_logic                       :=  '0';
  signal tb_clk:          std_logic                       :=  '0';
  signal tb_rst:          std_logic                       :=  '1';

  signal tb_sin_in:       signed(15 downto 0)             := (others => '0');
  signal tb_cos_in:       signed(15 downto 0)             := (others => '0');
  signal tb_ang_in:       signed(15 downto 0)             := (others => '0');

  signal tb_sin_out:      signed(15 downto 0);
  signal tb_cos_out:      signed(15 downto 0);
  signal tb_ang_out:      signed(15 downto 0);
begin

  cordic_uut: entity work.cordic
  port map(
    clk     => tb_clk,
    rst     => tb_rst,

    sin_in  => tb_sin_in,
    cos_in  => tb_cos_in,
    ang_in  => tb_ang_in,

    sin_out => tb_sin_out,
    cos_out => tb_cos_out,
    ang_out => tb_ang_out
          );

	clk_process: process
	begin
    while wait_flag = '0' loop
      tb_clk	<=	'1';
      wait for clk_period/2;
      tb_clk	<=	'0';
      wait for clk_period/2;
    end loop;
    wait;
	end process;

	stimulus_process: process
	begin

    wait for clk_period * 16;
    wait_flag   <=  '1';
    wait;
  end process;

end architecture;
