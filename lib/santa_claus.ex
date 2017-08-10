defmodule SantaClaus do

  #   This is an Elixir solution "The Santa Claus problem"
  #   as discussed by Simon Peyton Jones (with a Haskell solution using
  #   Software Transactional Memory) in "Beautiful code".
  #
  #   This implementation is based on the Erlang solution proposed by Richard A. O'Keefe
  #   http://www.cs.otago.ac.nz/staffpriv/ok/santa/santa.erl
  #
  #   J.A.Trono "A new exercise in concurrency", SIGCSE 26:8-10, 1994.
  #
  #    	Santa repeatedly sleeps until wakened by either all of his
  #    	nine reindeer, back from their holidays, or by a group of three
  #    	of his ten elves.  If awakened by the reindeer, he harnesses
  #    	each of them to his sleight, delivers toys with them, and finally
  #    	unharnesses them (allowing them to go off on holiday).  If
  #    	awakened by a group of elves, he shows each of the group into
  #    	his study, consults with them on toy R&D, and finally shows them
  #    	each out (allowing them to go back to work).  Santa should give
  #    	priority to the reindeer in the case that there is both a group
  #    	of elves and a group of reindeer waiting.
  #
  #    O'Keefe soved the problem by introducing two secretaries: Robin and Edna.
  #    The reindeer ask Robin for appointments. As soon as she has nine waiting
  #    reindeer she sends them as a group to Santa.
  #    The elves as Edna for appointments. As soon as she has three waiting elves
  #    she sends them as a group to Santa.
  #

  defp worker(secretary, message) do
    receive do after :rand.uniform(1000) -> :ok end    # random delay
    send secretary, self()			                        # send my pid to the secretary
    gate_keeper = receive do x -> x end   	            # await permission to enter
    IO.puts message                                   # do my action
    send gate_keeper, {:leave, self()}	                # tell the gate-keeper I'm done
    worker(secretary, message)		                    # do it all again
  end

  defp secretary(santa, species, count) do
    secretary_loop(count, [], {santa, species, count})
  end

  defp secretary_loop(0, group, {santa, species, count}) do
    send santa, {species, group}
    secretary(santa, species, count);
  end

  defp secretary_loop(n, group, state) do
    receive do
      pid -> secretary_loop(n-1, [pid| group], state)
    end
  end

  defp santa() do
    {species,group} =
      receive do				            # first pick up a reindeer group
         {:reindeer,g} -> {:reindeer,g}     # if there is one, otherwise
      after 0 ->
         receive	do		                # wait for reindeer or elves,
           {:reindeer,g} -> {:reindeer,g}
           {:elves,g}    -> {:elves,g}
         end			                    # whichever turns up first.
      end

    case species do
       :reindeer -> IO.puts("Ho, ho, ho!  Let's deliver toys!")
       :elves    -> IO.puts("Ho, ho, ho!  Let's meet in the study!")
    end

    for pid <- group, do: send pid, self()                          # tell them all to enter
    for _pid <- group, do: (receive do {:leave, _pid} -> :ok end)   # wait for each of them to leave

    santa()
  end

  defp spawn_worker(secretary, before, i, later) do
    message = before <> Integer.to_string(i) <> later
    spawn(fn () -> worker(secretary, message) end)
  end

  def start() do
    santa = spawn(fn () -> santa() end)
    robin = spawn(fn () -> secretary(santa, :reindeer, 9) end)
    edna  = spawn(fn () -> secretary(santa, :elves,    3) end)

    for i <- Range.new(1, 9), do: spawn_worker(robin, "Reindeer ", i, " delivering toys.")
    for i <- Range.new(1, 10), do: spawn_worker(edna,  "Elf ", i, " meeting in the study.\n")
  end

end
