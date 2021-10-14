int select_result[1000];
int *select_sort(int *a, int N)
{
	int m;
	for (m = 0; m <= N; m++)
	{
		select_result[m] = a[m];
	}

	int i, j, k, t;
	for (i = 0; i < N - 1; i++)
	{
		k = i;
		for (j = i + 1; j < N; j++)
		{
			if (select_result[j] < select_result[k])
			{
				k = j;
			}
		}

		t = select_result[i];
		select_result[i] = select_result[k];
		select_result[k] = t;
	}
	return select_result;
}
