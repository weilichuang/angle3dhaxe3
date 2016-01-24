/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.time;

class JobHandler implements TimelineListener
{
	var _jobId:Int;
	var _job:Job;
	
	public function new(job:Job = null)
	{
		_job = job;
		_jobId = -1;
	}
	
	public function run(job:Job = null, duration:Float, delay = 0.):JobHandler
	{
		if (job != null) _job = job;
		_jobId = Timeline.schedule(this, duration, delay);
		return this;
	}
	
	public function cancel()
	{
		if (_job != null && _jobId != -1)
			Timeline.cancel(_jobId);
	}
	
	function onInstant(id:Int, iteration:Int) {}
	
	function onStart(id:Int, iteration:Int)
	{
		_job.onStart();
	}
	
	function onProgress(alpha:Float)
	{
		_job.onProgress(alpha);
	}
	
	function onFinish(id:Int, iteration:Int)
	{
		if (_job != null)
		{
			_job.onComplete();
			_job = null;
		}
	}
	
	function onCancel(id:Int)
	{
		if (_job != null)
		{
			_job.onAbort();
			_job = null;
		}
	}
}