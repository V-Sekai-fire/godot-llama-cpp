#pragma once

#include <queue>
#include <mutex>
#include <string>

// Thread-safe data for completion chunks
struct completion_data {
	int id;
	std::string text;
	std::string error;
	bool done;
};

// Simple thread-safe queue for completion chunks
class CompletionQueue {
	std::queue<completion_data> queue;
	std::mutex mutex;

public:
	void push(const completion_data& chunk) {
		std::lock_guard<std::mutex> lock(mutex);
		queue.push(chunk);
	}

	bool pop(completion_data& chunk) {
		std::lock_guard<std::mutex> lock(mutex);
		if (queue.empty()) {
			return false;
		}
		chunk = queue.front();
		queue.pop();
		return true;
	}

	bool empty() {
		std::lock_guard<std::mutex> lock(mutex);
		return queue.empty();
	}
};
