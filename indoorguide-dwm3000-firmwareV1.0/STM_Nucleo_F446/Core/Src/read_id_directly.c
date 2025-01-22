/**------------  Make sure that your readfromspi is connected to the HAL properly  ---------------- **/

/*! ------------------------------------------------------------------------------------------------------------------
 * Function: readfromspi()
 *
 * Low level abstract function to read from the SPI
 * Takes two separate byte buffers for write header and read data
 * returns the offset into read buffer where first byte of read data may be found,
 * or returns -1 if there was an error
 */

int readfromspi(uint16_t headerLength, uint8_t *headerBuffer, uint16_t readlength, uint8_t *readBuffer)
{

    decaIrqStatus_t stat;
    stat = decamutexon();

    /* Blocking: Check whether previous transfer has been finished */
    while (HAL_SPI_GetState(&hspi4) != HAL_SPI_STATE_READY);

    HAL_GPIO_WritePin(DW_CS_GPIO_Port, DW_CS_Pin, 0); /**< Put chip select line low */

    /* Send header */
    HAL_SPI_Transmit(&hspi4, (uint8_t*)headerBuffer, headerLength, HAL_MAX_DELAY); //No timeout

    while(__HAL_SPI_GET_FLAG(&hspi4, SPI_FLAG_TXE) == RESET)//Verify that the transmit was ended
    {
    }

    /* for the data buffer use LL functions directly as the HAL SPI read function
     * has issue reading single bytes */
    while (readlength-- > 0)
    {
        /* Wait until TXE flag is set to send data */
        while(__HAL_SPI_GET_FLAG(&hspi4, SPI_FLAG_TXE) == RESET)
        {
        }

        (&hspi4)->Instance->DR=0;
        /* set output to 0 (MOSI), this is necessary for
        e.g. when waking up DW3000 from DEEPSLEEP via dwt_spicswakeup() function.
        */

        /* Wait until RXNE flag is set to read data */
        while(__HAL_SPI_GET_FLAG(&hspi4, SPI_FLAG_RXNE) == RESET)
        {
        }

        (*readBuffer++) = (&hspi4)->Instance->DR;  //copy data read form (MISO)
    }


    HAL_GPIO_WritePin(DW_CS_GPIO_Port, DW_CS_Pin, 1); /**< Put chip select line high */

    decamutexoff(stat);

    return 0;
} // end readfromspi()

/**------------------ Then test using these functions copied from the library which you can't access -------------------------- **/

void my_dwt_readfromdevice
(
    uint16_t  recordNumber,
    uint16_t  index,
    uint32_t        length,
    uint8_t         *buffer
)
{
    uint8_t header[3] ; // Buffer to compose header in
    int   cnt = 0; // Counter for length of header
#ifdef DWT_API_ERROR_CHECK
    assert(recordNumber <= 0x3F); // Record number is limited to 6-bits.
#endif

    // Write message header selecting READ operation and addresses as appropriate (this is one to three bytes long)
    if (index == 0) // For index of 0, no sub-index is required
    {
        header[cnt++] = (uint8_t) recordNumber ; // Bit-7 zero is READ operation, bit-6 zero=NO sub-addressing, bits 5-0 is reg file id
    }
    else
    {
#ifdef DWT_API_ERROR_CHECK
        assert((index <= 0x7FFF) && ((index + length) <= 0x7FFF)); // Index and sub-addressable area are limited to 15-bits.
#endif
        header[cnt++] = (uint8_t)(0x40 | recordNumber) ; // Bit-7 zero is READ operation, bit-6 one=sub-address follows, bits 5-0 is reg file id

        if (index <= 127) // For non-zero index < 127, just a single sub-index byte is required
        {
            header[cnt++] = (uint8_t) index ; // Bit-7 zero means no extension, bits 6-0 is index.
        }
        else
        {
            header[cnt++] = 0x80 | (uint8_t)(index) ; // Bit-7 one means extended index, bits 6-0 is low seven bits of index.
            header[cnt++] =  (uint8_t) (index >> 7) ; // 8-bit value = high eight bits of index.
        }
    }

    // Do the read from the SPI
    readfromspi(cnt, header, length, buffer);  // result is stored in the buffer
} // end dwt_readfromdevice()

/** ------------------------------------------------- **/

uint32_t my_dwt_read32bitoffsetreg(int regFileID, int regOffset)
{
    uint32_t  regval = 0 ;
    int     j ;
    uint8_t   buffer[4] ;

    my_dwt_readfromdevice(regFileID,regOffset,4,buffer); // Read 4 bytes (32-bits) register into buffer

    for (j = 3 ; j >= 0 ; j --)
    {
        regval = (regval << 8) + buffer[j] ;
    }
    return regval ;

} // end dwt_read32bitoffsetreg()

/**----------Finally, in main you just call this -----------**/

my_dwt_read32bitoffsetreg(0,0); //reads the devID directly.