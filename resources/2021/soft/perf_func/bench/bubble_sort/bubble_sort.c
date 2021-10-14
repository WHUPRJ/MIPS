int bubble_result[1000];
int *bubble_sort(int *a, int N)
{
	int m;
	for (m = 0; m <= N; m++)
	{
		bubble_result[m] = a[m];
	}

	int i, j, t;
	for (j = 0; j < N; j++)
	{
		for (i = 0; i < N - 1 - j; i++)
		{
			if (bubble_result[i] > bubble_result[i + 1])
			{
				t = bubble_result[i];
				bubble_result[i] = bubble_result[i + 1];
				bubble_result[i + 1] = t;
			}
		}
	}
	return bubble_result;
}
