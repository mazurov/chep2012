#1

Hello, my name is Sasha Mazurov. I'm a PhD student at Ferrara university, the last 5 years I'm working at CERN.
Here I would like to share our experience of using VT profiler tool at LHCb experiment in CERN.

#2 

I'm going to say a few words about why we need profilers at HEP, present basic profiling techniques and show what profilers are used at LHCb experiment.

Then overview the VTune Amplifier Tool and at last three sections show how this tools was integrated to Gaudi framework - event processing framework at LHCb

Lets start

#3 
Generally, the major HEP software is an event processing software. We simulate event, collect events from detectors, save it to storage, analyze aa the grid and final output is research papers, the Higgs boson, and , probably, Nobel prize.

The crucial characteristic of this software is an events processing speed - all we want to receive results as soon as possible.


#4
For example, high events processing rate is important at trigger software. At LHCb we need to process 1 million events per second.

We can achieve this rate by two ways. First, buy fast hardware and to write fast algorithms. Let's focus on algorithms.

If your application have a lot of lines of code, many algorithms and functions then to improve the speed you need a specialized tools ...

#5
... profilers, that helps to analyze the performance of the application 

#6
Particularly we need a CPU profilers to measure the frequency and duration of functions calls and/or code instructions.

#7
Basically this tools use two techniques that we can mix together - use hardware counters and change the application code.

#8 
Modern chipsets has a specialized performance registers that count hardware events like cache misses, number of cycles, memory access. A little disadvantage is that only hardware specialist could interpret the results.

At LHCb we use two tools of this type: perfmon2 and VTune.

#9
By instrumenting the code  time measuring functions can be inserted manually to the code or by automatic tool.
Some compilers can have ability to insert those functions at compile time. For example, gcc has this feature. The disadvantage of static method is that the source codebase should be changed, but usually we could not change code or recompile all used external libraries.

Nowadays the popular method is to modify the code at run-time. In this case the profiling tool could replace the standard libraries, inject an agent that interrupts the target application and looks to the current state or event to execute the program at specialized virtual machine.

At LHCb we use three tools of this type: valgrind, google performance tools and VTune. Lets focus on VTune

#10
Vtune is a profiling tool that runs on linux and windows, has a perfect graphical and command line interface. It's a proprietary software, but as a CERN user you can used for free at lxplus cluster.

#12
VTune can collect hardware event, analyze multi-threading bottlenecks and use the user-mode sampling. 

#13 
User-mode sampling works simple: VTune preload an agent library that frequently interrupt a target process, collect samples of all active instruction addresses and finally restore a call sequence for each sample. With this sampling we
can ...

#14
... do the concurrency analysis and find the hotspots. Generally the hotspots are the functions or code instruction that occurs frequently in samples.

#15
Here the basic VTune CPU usage report. At first column you can see the functions ordered by CPU time usage in reverse order. So hotspot functions are at the top. At last column is a shared libraries where the function is defined.

#16
Besides the grouping by function name, we can group results by shared library, by class, by source file, thread

#17
Or we can see the time usage at the call chain.

#18
The striking feature of VTune is an ability to filter results and to show CPU time usage at the selected time interval. 

#19
If a program is compiler with debug symbols you can see CPU time usage by source line

#20
I need to point out that user-mode sampling is a statistical method and measuring accuracy depends on duration profiling, on fast hardware you need to run profilng longer. The important parameter is a sampling interval. Intel recommends to use 10ms interval. In this case the application runs only 5% as slower as running outside the VTune 

#21
We can run profiling without modifying the codebase, but at LHCb we got more profiling reports by  using VTune User API in our event processing framework ...

#22
... Gaudi. But first, a little bit about Gaudi. Gaudi a core software framework written in LHCb and configurable from python. All specialized frameworks are based on Gaudi

#22
By design, the framework decouples the objects describing the data and those implementing the algorithms. Due to this design, developers can concentrate only on physics related tasks in algorithms and usually do not care about other parts of the framework.

The basic gaudi modules are algorithms, service and tools. At event loop we run user algorithms that calls the services and tools.

#23

This a part of algorithms sequence at trigger software. Event comes to the first algorithm, it process event and new results are available to the next algorithm, then next, then next to the end. 

Each algorithm himself can execute another algorithms. So the algorithms sequence has an hierarchical structure. Moreover the same algorithm can appears more than one in sequence.

The question raised - how to identify slow functions (hotspots) in algorithms. We can use Intel VTune Amplifier, but it knows nothing about framework modules - algorithms and provide reports only on lower lever of functions calls. 

#24
For that reason we developed a new tool named Gaudi Intel Profiling Auditor, that use VTune User library and extend Gaudi Auditors

#25
VTune User API is a C library that can be integrated to the user framework. It provides functions that control the profiling process:
For us were interesting two types of functions:
(1) Start/pause profiling. With this functions we can skip unimportant code regions like initialization and finalization and concentrate only on event loop.
(2) With mark regions functions we can mark the functions with some name.  In our case it will be a name that represent an sequence branch where the function appears.


#26
Gaudi provides hooks to execute user defines actions at the beginning and at the end of each algorithm execution. This actions are places to specialized components named auditors in Gaudi. So we created Gaudi Intel Profiler Auditor and use VTune User API functions there.

#27
As a result we got the  new report. CPU usage per algorithm branch. Here we can see, for example, that  application spent 41.213s in algorithm Hlt1TrackAllL0Unit that was called from sequence Hlt1TrackAllL0FilterSequence

#28
Moreover, we got the hotspot functions of algorithm. So using VTune user API in Gaudi we can point out the slow parts of algorithms. 

#29
In Gaudi we can configure components in python (but at the end a native compiled C++ code is running). Here is an example of configuring auditor. 

We can set what events profile.

#30
Then we run a target program. “intelprofiler” is our wrapper over amplxe-cl VTune command line tool.
We can analyze collected data from GUI or from command line

#31
At the last section I present an interesting example of using VTune at LHCb.

#32
At first example, we studied how the application performance would change if use non standard memory allocation functions.

We run the application twice. First, we use standard functions. Second, the functions from tcmalloc library.

We compared results and saw that function tc_new use twice less time then operator new. It was observed that using tcmalloc library improves 

#33

At second example, we studied the accuracy of user-mode sampling by comparing algorithms time distribution values received by Intel Profiling Auditor and by Gaudi Timing Auditor. Timer Auditor measures the absolute time of algorithm's run, so we can use his values as reference.

At the tables you can see that both auditors identify the same hotspot algorithms and the difference between algorithms time distribution is less than 2% when we  processed 1000 events. Here the time distribution is measured relative to the top algorithm.

#34
And the last example.

VTune Amplifier can export collected results to CSV format, so, for example, we can import it to excel and build a custom reports. Here we can see algorithms time distribution.

#35
So, I hope that you will like the VTune Amplifier tool. It has everything to find hotspots
 
You can integrate it to your framework and profiling it  in reasonable time (as I mentioned  with 10ms sampling interval you have about 5% overhead).

Thank you.






















