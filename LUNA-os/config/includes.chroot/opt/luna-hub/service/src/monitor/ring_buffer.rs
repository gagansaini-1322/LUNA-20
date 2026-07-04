//! Bounded ring buffer for short time-series histories. Used for CPU/FPS
//! frames so the daemon can compute one-percent-low or rolling averages
//! without keeping unbounded state.

use std::collections::VecDeque;

#[derive(Debug, Clone)]
pub struct RingBuffer<T> {
    cap: usize,
    inner: VecDeque<T>,
}

impl<T> RingBuffer<T> {
    pub fn with_capacity(cap: usize) -> Self {
        debug_assert!(cap > 0);
        Self {
            cap,
            inner: VecDeque::with_capacity(cap),
        }
    }

    pub fn push(&mut self, value: T) {
        if self.inner.len() == self.cap {
            self.inner.pop_front();
        }
        self.inner.push_back(value);
    }

    pub fn len(&self) -> usize {
        self.inner.len()
    }

    pub fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    pub fn capacity(&self) -> usize {
        self.cap
    }

    pub fn as_slice(&self) -> Vec<&T> {
        self.inner.iter().collect()
    }

    pub fn clear(&mut self) {
        self.inner.clear();
    }

    /// Returns the average of the last `n` samples. If fewer samples are
    /// buffered, averages whatever is present.
    pub fn avg(&self) -> Option<T>
    where
        T: Copy + std::ops::Add<Output = T> + std::ops::Div<f32, Output = T> + From<u8>,
    {
        if self.inner.is_empty() {
            return None;
        }
        let mut acc = T::from(0u8);
        for v in &self.inner {
            acc = acc + *v;
        }
        let n = self.inner.len() as f32;
        Some(acc / n)
    }

    /// Returns the value at the given percentile (0.0..=1.0). For
    /// N samples, `kind` == "low" returns `samples[floor(N * pct)]`
    /// after sorting ascending.
    pub fn percentile(&self, pct: f32) -> Option<T>
    where
        T: Copy + PartialOrd,
    {
        if self.inner.is_empty() || !(0.0..=1.0).contains(&pct) {
            return None;
        }
        let mut values: Vec<T> = self.inner.iter().copied().collect();
        values.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        let idx = ((values.len() as f32 - 1.0) * pct).round() as usize;
        Some(values[idx])
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bounded_push_evicts_oldest() {
        let mut rb: RingBuffer<u32> = RingBuffer::with_capacity(3);
        rb.push(1);
        rb.push(2);
        rb.push(3);
        rb.push(4);
        assert_eq!(rb.len(), 3);
        assert_eq!(rb.as_slice(), vec![&2, &3, &4]);
    }

    #[test]
    fn avg_computes_mean() {
        let mut rb: RingBuffer<f32> = RingBuffer::with_capacity(4);
        rb.push(10.0);
        rb.push(20.0);
        rb.push(30.0);
        let avg = rb.avg().unwrap();
        assert!((avg - 20.0).abs() < 1e-4);
    }

    #[test]
    fn percentile_picks_correct_value() {
        let mut rb: RingBuffer<f32> = RingBuffer::with_capacity(10);
        for v in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0] {
            rb.push(v);
        }
        assert_eq!(rb.percentile(0.0).unwrap(), 1.0);
        assert_eq!(rb.percentile(1.0).unwrap(), 10.0);
        assert_eq!(rb.percentile(0.5).unwrap(), 6.0);
    }
}
